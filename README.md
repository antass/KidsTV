# KidsTV

A tvOS app that shows a curated grid of shows/movies for kids. Each tile is a
thumbnail that deep-links into the right streaming app (Netflix, Disney+, etc.)
straight to a specific title. No browsing, no recommendations, no store.

The catalog is just a JSON file — edit `KidsTV/Data/shows.json` to change what
appears. No code changes required to curate.

## Status

Initial scaffold. Needs an Xcode project wrapper, app icon, and real thumbnails.
The Swift sources, data model, and sample catalog are in place.

## Prerequisites

- macOS with Xcode 15+ installed
- An Apple ID (free tier is fine for on-device testing on your own Apple TV)
- The streaming apps you care about (Netflix, Disney+, etc.) already installed
  and signed in on the target Apple TV

## One-time setup: create the Xcode project

The repo intentionally does not include an `.xcodeproj` — those are messy to
hand-edit. Create it once in Xcode and drop these files in:

1. Open Xcode → **File → New → Project…**
2. Pick **tvOS → App**. Click Next.
3. Fill in:
   - Product Name: `KidsTV`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Uncheck "Include Tests" unless you want them.
4. Save the new project **inside** this `KidsTV/` directory (so the new
   `KidsTV.xcodeproj` lives alongside the existing `KidsTV/` source folder).
5. In Xcode's Project Navigator, delete the `ContentView.swift` and
   `KidsTVApp.swift` that Xcode generated (move to trash — they conflict with
   the ones in this repo).
6. Right-click the `KidsTV` group → **Add Files to "KidsTV"…** → select the
   `Models/`, `Views/`, and `Data/` folders from this repo. Make sure
   **"Create folder references"** is selected (blue folder icon) for `Data/`
   so `shows.json` is copied into the bundle as a resource.
7. Also add `KidsTVApp.swift` at the root of the `KidsTV/` folder.
8. Build target: tvOS 17.0 or later (for `NavigationStack`).

## Running

- **Simulator (fastest loop):** In Xcode, pick any **Apple TV** simulator from
  the run destination dropdown, then ⌘R. Deep links won't actually open
  Netflix/Disney+ in the simulator — you'll only see the dashboard.
- **Real Apple TV:** See `docs/testing-on-apple-tv.md` (TODO). Short version:
  enable Developer Mode on the Apple TV, pair it with Xcode over the same
  Wi-Fi, pick it as the run destination, ⌘R.

## Adding / removing shows

Edit `KidsTV/Data/shows.json`. Each entry:

```json
{
  "id": "unique-string",
  "title": "Displayed under the tile",
  "service": "Netflix | Disney+ | Apple TV+ | ...",
  "thumbnail": "name-of-image-in-Assets.xcassets",
  "deepLink": "https://... or nflx://... or disneyplus://..."
}
```

Thumbnails must be added to `Assets.xcassets` as image sets with the same name
referenced in `thumbnail`. Rebuild to pick up changes.

## Deep link notes — read before curating

- **Netflix:** `nflx://www.netflix.com/title/<id>` generally works on tvOS.
  Get the id from the web URL (`netflix.com/title/80020935`).
- **Disney+:** No official public URL scheme on tvOS. HTTPS links may open in
  a browser rather than the app. Expect trial-and-error per title.
- **Apple TV+ / Apple TV app:** Use `https://tv.apple.com/...` links — these
  open the TV app natively on tvOS.
- **YouTube:** Avoid. The YouTube app ignores deep links on tvOS in practice.

If a link fails to open, tvOS silently does nothing. Test each title on the
real device before handing the remote to a kid.

## Caveats / known limits

- tvOS does not guarantee that every custom URL scheme opens the target app.
  Schemes are undocumented and can change between app versions.
- If a streaming app is logged out or not installed, the deep link will fail.
- This app does **not** authenticate with streaming services. It only launches
  them. Logins happen inside each streaming app on the Apple TV.

## Project layout

```
KidsTV/
├── KidsTVApp.swift           # App entry
├── Models/
│   ├── Show.swift            # Single show/movie
│   └── Catalog.swift         # Loads shows.json from bundle
├── Views/
│   ├── DashboardView.swift   # Grid of tiles
│   └── ShowTile.swift        # One tile + deep-link action
├── Data/
│   └── shows.json            # Curated catalog (edit this)
└── Assets.xcassets/          # Thumbnails + app icon (add in Xcode)
```
