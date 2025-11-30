import SwiftUI
import UIKit

// MARK: - TileRevealView (T024, T025, T026)

/// View that progressively reveals a photo using a tile-based grid animation
struct TileRevealView: View {

    // MARK: - Properties

    let image: UIImage
    let revealedTiles: Set<Int>
    let gridSize: Int

    // MARK: - Constants

    private static let defaultGridSize = 6

    // MARK: - Initialization

    init(image: UIImage, revealedTiles: Set<Int>, gridSize: Int = defaultGridSize) {
        self.image = image
        self.revealedTiles = revealedTiles
        self.gridSize = gridSize
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let tileSize = size / CGFloat(gridSize)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(tileSize), spacing: 0), count: gridSize),
                spacing: 0
            ) {
                ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                    TileView(
                        image: image,
                        index: index,
                        gridSize: gridSize,
                        tileSize: tileSize,
                        isRevealed: revealedTiles.contains(index)
                    )
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.3), radius: 20)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - TileView (T024)

/// Individual tile component with flip animation
struct TileView: View {

    // MARK: - Properties

    let image: UIImage
    let index: Int
    let gridSize: Int
    let tileSize: CGFloat
    let isRevealed: Bool

    // MARK: - State

    @State private var rotation: Double = 0

    // MARK: - Computed Properties

    private var row: Int { index / gridSize }
    private var column: Int { index % gridSize }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Photo tile (revealed side)
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: tileSize * CGFloat(gridSize), height: tileSize * CGFloat(gridSize))
                .offset(
                    x: -CGFloat(column) * tileSize + (tileSize * CGFloat(gridSize - 1)) / 2,
                    y: -CGFloat(row) * tileSize + (tileSize * CGFloat(gridSize - 1)) / 2
                )
                .frame(width: tileSize, height: tileSize)
                .clipped()
                .opacity(isRevealed ? 1 : 0)

            // Hidden tile (back side)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Image(systemName: "questionmark")
                        .font(.system(size: tileSize * 0.3))
                        .foregroundStyle(.white.opacity(0.3))
                )
                .frame(width: tileSize, height: tileSize)
                .opacity(isRevealed ? 0 : 1)
        }
        .rotation3DEffect(
            .degrees(rotation),
            axis: (x: 0, y: 1, z: 0)
        )
        .onChange(of: isRevealed) { _, newValue in
            if newValue {
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                    rotation = 180
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TileRevealView(
        image: UIImage(systemName: "photo")!,
        revealedTiles: Set([0, 5, 10, 15, 20, 25, 30, 35]),
        gridSize: 6
    )
    .frame(width: 800, height: 800)
    .padding()
}
