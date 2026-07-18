# FTBS Bible (SwiftUI)

This project is a SwiftUI Bible reader built from the FTBS JSON data files.

## Included features

- Telugu and English Bible loading from bundled JSON
- Book and chapter navigation
- Previous/next chapter controls
- Search in the current book or the entire Bible
- Cross-reference lookup from `crossReferences.json`
- Footnote display for verses that include `footnotes`
- Optional parallel verse display in the other language
- Adjustable font size

## Data files

The app bundles these files inside `ftbs/BibleData/`:

- `english.json`
- `telugu.json`
- `crossReferences.json`

## Main Swift files

- `ftbs/ContentView.swift` — main SwiftUI reader UI
- `ftbs/BibleModels.swift` — Codable models and text helpers
- `ftbs/BibleViewModel.swift` — loading, navigation, search, and cross-reference logic
- `ftbs/ftbsApp.swift` — app entry point

## Run

Open `ftbs.xcodeproj` in Xcode and run the `ftbs` scheme.

If command-line builds fail on this machine, switch the active developer directory to a full Xcode installation first.

## App Store Connect upload

The file App Store Connect expects is an exported signed `.ipa`, not the source project.

1. Open `ftbs.xcodeproj` in Xcode.
2. Make sure signing is configured for your Apple Developer team.
3. Choose **Product > Archive**.
4. In Organizer, choose **Distribute App** and export for **App Store Connect**.
5. If you prefer command-line export, use `ExportOptions-AppStore.plist` with `xcodebuild -exportArchive` after creating an archive.

## App Encryption / Export Compliance

This app uses only standard Apple-provided encryption through the operating system and framework APIs. It does not contain custom cryptography, third-party encryption libraries, or user-facing secure messaging features.

### App Store Connect answer

- **Uses encryption:** Yes, via Apple system services only
- **Uses non-exempt encryption:** No
- **Export compliance key:** `ITSAppUsesNonExemptEncryption = NO`

This is also set in the Xcode build settings for both Debug and Release configurations.

