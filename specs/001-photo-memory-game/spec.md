# Feature Specification: PhotoQuizz - Photo Memory Game

**Feature Branch**: `001-photo-memory-game`
**Created**: 2025-11-30
**Status**: Draft
**Input**: User description: "Une application tvOS dernière génération, qui propose un jeu chill et familial, qui va permettre de se replonger dans ses souvenirs. L'idée est d'aller piocher dans les photos de l'utilisateur avec une apparition progressive pour lui laisser le temps de deviner où a été prise la photo. Une fois le temps imparti ou à la demande de l'utilisateur une carte apparaît avec l'endroit où a été prise la photo, une indication de la ville et pays, ainsi que la date. Ce sera le mode principal de jeux, mais je prévois de développer d'autres modes plus compétitifs, avec placement sur une carte un peu comme GeoGuessr."

## Clarifications

### Session 2025-11-30

- Q: What type of progressive reveal animation should be used for photos? → A: Tile reveal - photo divided into grid, tiles flip/appear randomly
- Q: How should the app handle network failure for maps/geocoding? → A: Graceful fallback - show photo location as coordinates only (no map/city name)
- Q: How should game session length be configured? → A: Predefined lengths - user chooses from options (5, 10, 20, or endless)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Play Discovery Mode Solo (Priority: P1)

A user wants to relax and reminisce by playing a guessing game with their own photos. They launch the app on their Apple TV, grant access to their photo library, and start a game session. A photo from their library gradually reveals itself on screen. The user tries to remember where and when the photo was taken. When ready (or when time runs out), they press a button to reveal the answer: a map showing the exact location, along with the city, country, and date.

**Why this priority**: This is the core game loop and primary value proposition. Without this, there is no product.

**Independent Test**: Can be fully tested by launching the app, selecting a photo album, and playing through one complete round of photo reveal → guess → answer reveal.

**Acceptance Scenarios**:

1. **Given** the user has granted photo library access and has geotagged photos, **When** they start a game session, **Then** a random photo begins revealing progressively on screen
2. **Given** a photo is revealing on screen, **When** the user presses the reveal button or the timer expires, **Then** a map displays showing the photo location with city, country, and date information
3. **Given** the answer has been revealed, **When** the user presses continue, **Then** the next photo begins revealing

---

### User Story 2 - Browse and Select Photo Albums (Priority: P2)

A user wants to play with photos from a specific trip or time period. They navigate to the album selection screen and choose which albums or memories to include in their game session. This allows them to focus on specific memories rather than their entire library.

**Why this priority**: Enhances user control and personalization but the core game can work without it by using all available photos.

**Independent Test**: Can be tested by navigating to album selection, choosing specific albums, and verifying only photos from those albums appear in gameplay.

**Acceptance Scenarios**:

1. **Given** the user is on the home screen, **When** they navigate to album selection, **Then** they see a list of their photo albums and smart albums
2. **Given** the user has selected specific albums, **When** they start a game session, **Then** only photos from selected albums are used
3. **Given** no albums are selected, **When** the user starts a game, **Then** photos from all accessible albums are used

---

### User Story 3 - Customize Game Settings (Priority: P3)

A user wants to adjust the difficulty by changing how quickly photos reveal or how long they have to guess. They access the settings and configure reveal speed and timer duration to match their preference.

**Why this priority**: Improves user experience but the game works well with default settings.

**Independent Test**: Can be tested by changing settings and verifying the game behavior matches the new configuration.

**Acceptance Scenarios**:

1. **Given** the user is in settings, **When** they adjust the reveal speed, **Then** photos reveal faster or slower in subsequent games
2. **Given** the user is in settings, **When** they adjust the timer duration, **Then** the countdown reflects the new duration in games
3. **Given** the user is in settings, **When** they select a session length (5, 10, 20, or endless), **Then** the game uses that number of photos
4. **Given** the user has never changed settings, **When** they play a game, **Then** default values are used (medium reveal speed, 30-second timer, 10-photo session)

---

### User Story 4 - Navigate with Siri Remote (Priority: P1)

A user sitting on their couch navigates the entire app using only the Siri Remote. All interactions work smoothly with the touchpad, click, and Menu buttons. Focus states are clear and navigation feels intuitive on the big screen.

**Why this priority**: Essential for tvOS - without proper remote navigation, the app is unusable.

**Independent Test**: Can be tested by navigating through all screens using only the Siri Remote without touching any other device.

**Acceptance Scenarios**:

1. **Given** any screen in the app, **When** the user swipes on the touchpad, **Then** focus moves predictably between interactive elements
2. **Given** a focusable element, **When** the user clicks the touchpad, **Then** the expected action occurs
3. **Given** any screen except the home screen, **When** the user presses the Menu button, **Then** they navigate back to the previous screen

---

### User Story 5 - Grant Photo Library Access (Priority: P1)

A first-time user launches the app and is prompted to grant access to their photo library. The app explains why access is needed. Once granted, photos become available for gameplay. If denied, the app explains that it cannot function without photo access.

**Why this priority**: Without photo access, the app has no content to display.

**Independent Test**: Can be tested by launching the app fresh (or resetting permissions) and going through the permission flow.

**Acceptance Scenarios**:

1. **Given** a first launch with no permissions, **When** the app starts, **Then** a clear explanation screen appears before requesting permission
2. **Given** the permission prompt appears, **When** the user grants access, **Then** the app proceeds to the home screen with photos available
3. **Given** the permission prompt appears, **When** the user denies access, **Then** the app displays an explanation screen with instructions to enable access in Settings

---

### Edge Cases

- What happens when a photo has no geolocation data? → The photo is skipped and another is selected
- What happens when a photo has no date metadata? → Display "Date unknown" in the reveal screen
- What happens when the user has fewer than 5 geotagged photos? → Display a message suggesting they add more geotagged photos, but allow playing with available photos
- What happens when the user revokes photo access mid-session? → Return to home screen with a message explaining access was lost
- What happens when the timer is paused (app goes to background)? → Timer pauses and resumes when app returns to foreground
- What happens when network is unavailable for map/geocoding? → Display photo location as GPS coordinates only (latitude/longitude), without map or city/country name

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST request and handle photo library read access permission
- **FR-002**: System MUST filter photos to only include those with valid geolocation metadata
- **FR-003**: System MUST progressively reveal photos using a tile-based animation (photo divided into grid, tiles flip/appear randomly) over a configurable duration
- **FR-004**: System MUST display a countdown timer during photo reveal phase
- **FR-005**: System MUST allow users to skip the timer and reveal the answer immediately
- **FR-006**: System MUST display a map centered on the photo's location when revealing the answer
- **FR-007**: System MUST display the city and country name derived from the photo's coordinates (or GPS coordinates as fallback when network unavailable)
- **FR-008**: System MUST display the date the photo was taken (or "Date unknown" if unavailable)
- **FR-009**: System MUST support navigation using only the Siri Remote (touchpad, click, Menu button)
- **FR-010**: System MUST provide clear focus states for all interactive elements
- **FR-011**: System MUST allow users to select specific albums to play with
- **FR-012**: System MUST persist user settings (reveal speed, timer duration, session length) between sessions
- **FR-016**: System MUST allow users to select session length from predefined options: 5, 10, 20 photos, or endless mode
- **FR-013**: System MUST gracefully handle photos without geolocation by skipping them
- **FR-014**: System MUST provide visual feedback during photo loading
- **FR-015**: System MUST pause the timer when the app goes to background

### Key Entities

- **Photo**: A user's photo with associated metadata (geolocation coordinates, date taken, album membership)
- **Game Session**: A play session containing a sequence of photos to guess, current progress, and settings
- **Location Reveal**: The answer display combining map view, reverse-geocoded address (city, country), and date
- **User Settings**: Persisted preferences including reveal speed, timer duration, session length (5/10/20/endless), and selected albums

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can start playing within 30 seconds of launching the app (after initial permission grant)
- **SC-002**: Photo reveal animation runs smoothly without visible stuttering on supported Apple TV hardware
- **SC-003**: Location and date information displays within 2 seconds of revealing the answer
- **SC-004**: Users can complete a 10-photo session without encountering errors or crashes
- **SC-005**: All navigation can be completed using only the Siri Remote with no more than 3 clicks to reach any feature
- **SC-006**: 90% of photos with valid geolocation display accurate city/country information
- **SC-007**: App launches and displays content within 3 seconds on Apple TV 4K

## Assumptions

- Users have an Apple TV running tvOS 17 or later
- Users have photos stored in their iCloud Photo Library or local device library
- Users have some photos with embedded GPS coordinates (geotagged photos)
- The Apple TV has network connectivity for map display and reverse geocoding
- Standard reveal speed of 10 seconds and timer duration of 30 seconds provide a good default experience
- Playing in landscape orientation only (standard tvOS)

## Out of Scope

- Competitive game modes with map placement (GeoGuessr-style) - planned for future release
- Multiplayer functionality
- Scoring or leaderboards
- Photo editing or sharing features
- Support for platforms other than tvOS
- Offline map functionality
