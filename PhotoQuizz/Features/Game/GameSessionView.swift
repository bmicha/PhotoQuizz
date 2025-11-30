import SwiftUI

// MARK: - GameSessionView (T030, T031, T032, T033, T034, T058)

/// Main game session view orchestrating the reveal → timer → answer flow
struct GameSessionView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(GeocodingService.self) private var geocodingService
    @Environment(SettingsService.self) private var settingsService
    @Environment(PhotoLibraryService.self) private var photoLibraryService

    // MARK: - Properties

    let photos: [PhotoItem]

    // MARK: - State

    @State private var gameSession: GameSession?
    @State private var currentImage: UIImage?
    @State private var locationReveal: LocationReveal?
    @State private var isLoadingImage = true
    @State private var isPaused = false
    @State private var accessRevoked = false

    @FocusState private var focusedButton: GameButton?

    // MARK: - Timer

    @State private var timer: Timer?

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            if let session = gameSession {
                gameContent(session: session)
            } else {
                // Loading state
                ProgressView("Loading game...")
                    .font(.title)
                    .foregroundStyle(.white)
            }
        }
        .onAppear {
            startGame()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .task {
            // T058: Monitor for photo access revocation
            await checkPhotoAccess()
        }
        .alert("Photo Access Revoked", isPresented: $accessRevoked) {
            Button("Return Home") {
                dismiss()
            }
        } message: {
            Text("Photo library access has been revoked. Please re-enable access in Settings to continue playing.")
        }
    }

    // MARK: - Game Content

    @ViewBuilder
    private func gameContent(session: GameSession) -> some View {
        VStack(spacing: 30) {
            // Header with progress and timer
            headerView(session: session)

            Spacer()

            // Main content based on phase
            switch session.phase {
            case .revealing:
                revealingPhase(session: session)

            case .revealed:
                revealedPhase(session: session)

            case .complete:
                completePhase(session: session)
            }

            Spacer()

            // Action buttons
            actionButtons(session: session)
        }
        .padding(60)
    }

    // MARK: - Header View

    private func headerView(session: GameSession) -> some View {
        HStack {
            // Progress
            Text("Photo \(session.progress.current) of \(session.progress.total)")
                .font(.system(size: 32))
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            // Timer (only during revealing phase)
            if session.phase == .revealing {
                CompactTimerView(remaining: session.timerRemaining)
            }
        }
    }

    // MARK: - Revealing Phase

    private func revealingPhase(session: GameSession) -> some View {
        VStack(spacing: 40) {
            if isLoadingImage {
                ProgressView()
                    .scaleEffect(2)
                    .tint(.white)
            } else if let image = currentImage {
                TileRevealView(
                    image: image,
                    revealedTiles: session.revealedTiles
                )
                .frame(maxHeight: 700)
            }

            Text("Where was this photo taken?")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Revealed Phase

    private func revealedPhase(session: GameSession) -> some View {
        HStack(spacing: 60) {
            // Photo
            if let image = currentImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 600, maxHeight: 600)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.5), radius: 20)
            }

            // Location reveal
            if let reveal = locationReveal, let photo = session.currentPhoto {
                LocationRevealView(locationReveal: reveal, photo: photo)
                    .frame(maxWidth: 800)
            } else {
                ProgressView("Loading location...")
                    .tint(.white)
            }
        }
    }

    // MARK: - Complete Phase

    private func completePhase(session: GameSession) -> some View {
        VStack(spacing: 40) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(.green)

            Text("Session Complete!")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.white)

            Text("You viewed \(session.progress.total) photos")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private func actionButtons(session: GameSession) -> some View {
        HStack(spacing: 40) {
            switch session.phase {
            case .revealing:
                // Reveal button (T032)
                GameActionButton(
                    title: "Reveal Answer",
                    icon: "eye.fill",
                    style: .primary
                ) {
                    revealAnswer()
                }
                .focused($focusedButton, equals: .reveal)

                // Quit button
                GameActionButton(
                    title: "Quit",
                    icon: "xmark",
                    style: .secondary
                ) {
                    dismiss()
                }
                .focused($focusedButton, equals: .quit)

            case .revealed:
                // Continue button (T033)
                if session.hasMorePhotos {
                    GameActionButton(
                        title: "Next Photo",
                        icon: "arrow.right",
                        style: .primary
                    ) {
                        nextPhoto()
                    }
                    .focused($focusedButton, equals: .next)
                }

                // Quit button
                GameActionButton(
                    title: session.hasMorePhotos ? "End Session" : "Done",
                    icon: session.hasMorePhotos ? "xmark" : "checkmark",
                    style: .secondary
                ) {
                    dismiss()
                }
                .focused($focusedButton, equals: .quit)

            case .complete:
                // Return home button (T034)
                GameActionButton(
                    title: "Return Home",
                    icon: "house.fill",
                    style: .primary
                ) {
                    dismiss()
                }
                .focused($focusedButton, equals: .home)
            }
        }
        .onAppear {
            focusedButton = session.phase == .revealing ? .reveal : .next
        }
    }

    // MARK: - Game Logic

    private func startGame() {
        let settings = settingsService.settings
        let session = GameSession(photos: photos, settings: settings)
        self.gameSession = session

        loadCurrentPhoto()
        startTimer()
        startTileReveal()
    }

    private func loadCurrentPhoto() {
        guard let session = gameSession, let photo = session.currentPhoto else { return }

        isLoadingImage = true

        Task {
            do {
                let image = try await photoLibraryService.loadImage(
                    for: photo.asset,
                    targetSize: CGSize(width: 1920, height: 1080)
                )

                await MainActor.run {
                    currentImage = image
                    isLoadingImage = false
                }
            } catch {
                print("Failed to load image: \(error)")
                await MainActor.run {
                    isLoadingImage = false
                }
            }
        }
    }

    // MARK: - Timer Logic (T031)

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard !isPaused else { return }
            gameSession?.tick()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isPaused = false
            // T058: Check photo access when returning to foreground
            Task {
                await checkPhotoAccess()
            }
        case .inactive, .background:
            isPaused = true
        @unknown default:
            break
        }
    }

    // MARK: - Photo Access Check (T058)

    private func checkPhotoAccess() async {
        let status = await photoLibraryService.requestAuthorization()
        if status != .authorized && status != .limited {
            await MainActor.run {
                stopTimer()
                accessRevoked = true
            }
        }
    }

    // MARK: - Tile Reveal Logic

    private func startTileReveal() {
        guard let session = gameSession else { return }

        let revealDuration = session.settings.revealSpeed.duration
        let totalTiles = GameSession.totalTiles
        let interval = revealDuration / Double(totalTiles)

        // Schedule tile reveals
        for i in 0..<totalTiles {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * Double(i)) {
                guard self.gameSession?.phase == .revealing else { return }
                self.gameSession?.revealNextTile()
            }
        }
    }

    // MARK: - Actions

    private func revealAnswer() {
        stopTimer()
        gameSession?.showAnswer()
        loadLocationReveal()
    }

    private func loadLocationReveal() {
        guard let photo = gameSession?.currentPhoto else { return }

        Task {
            let reveal = await geocodingService.reverseGeocode(
                photo.location,
                dateTaken: photo.dateTaken
            )

            await MainActor.run {
                locationReveal = reveal
            }
        }
    }

    private func nextPhoto() {
        gameSession?.nextPhoto()
        locationReveal = nil
        loadCurrentPhoto()
        startTimer()
        startTileReveal()
        focusedButton = .reveal
    }
}

// MARK: - GameButton Enum

private enum GameButton: Hashable {
    case reveal
    case next
    case quit
    case home
}

// MARK: - GameActionButton

private struct GameActionButton: View {
    enum Style {
        case primary
        case secondary
    }

    let title: String
    let icon: String
    let style: Style
    let action: () -> Void

    @Environment(\.isFocused) private var isFocused

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28))

                Text(title)
                    .font(.system(size: 32, weight: .semibold))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(backgroundView)
            .foregroundColor(foregroundColor)
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: shadowColor, radius: isFocused ? 15 : 0)
            .animation(.spring(duration: 0.3), value: isFocused)
        }
        .buttonStyle(.plain)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(backgroundColor)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isFocused ? .blue : .blue.opacity(0.8)
        case .secondary:
            return isFocused ? .gray.opacity(0.5) : .gray.opacity(0.3)
        }
    }

    private var foregroundColor: Color {
        .white
    }

    private var shadowColor: Color {
        switch style {
        case .primary:
            return isFocused ? .blue.opacity(0.5) : .clear
        case .secondary:
            return .clear
        }
    }
}

// MARK: - Preview

#Preview {
    GameSessionView(photos: [])
        .environment(PhotoLibraryService())
        .environment(GeocodingService())
        .environment(SettingsService())
}
