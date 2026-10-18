# KidsTV

A tvOS app with one screen: a curated grid of shows for the kids. Each tile
opens the right streaming app (Netflix, Disney+, …) straight to that title.
No browsing, no recommendations, no autoplay rabbit holes.

## Edit the catalog (no Xcode needed)

The grid comes from [`KidsTV/Data/shows.json`](KidsTV/Data/shows.json).
The app downloads the live copy from GitHub every time it opens, so:

1. Open the file on github.com (phone or Mac) → pencil icon → edit → **Commit**.
2. On the Apple TV, close and reopen KidsTV. GitHub can take up to ~5 minutes
   to serve the new version.

If the edit has a typo, the broken entry is skipped and everything else still
shows. If GitHub is unreachable, the app shows the last catalog it downloaded
(or, the first time, the copy built into the app).

### One show

```json
{
  "id": "octonauts",
  "title": "Octonauts",
  "subtitle": "Season 1",
  "service": "Netflix",
  "image": "https://image.tmdb.org/t/p/w780/c1zzrs1FY4ERgLVRho1OyDmjGS5.jpg",
  "links": [
    "nflx://www.netflix.com/title/80020935",
    "https://www.netflix.com/title/80020935"
  ]
}
```

| Field      | Required | Notes |
|------------|----------|-------|
| `id`       | yes | Any unique text. |
| `title`    | yes | Shown under the tile. |
| `subtitle` | no  | Smaller second line. |
| `service`  | yes | `Netflix`, `Disney+`, `Prime Video`, `Apple TV`, `Max`, `PBS Kids`, or anything else (sets the badge color). |
| `image`    | no  | Any 16:9 image URL. Leave it out and a colored title card is drawn instead. |
| `links`    | yes | Tried in order until one opens. After that, the app opens the service's home screen. If nothing opens, the kid sees "Ask a grown-up to check that Netflix is installed and signed in." |

The page title ("Kids' Picks") is the top-level `"title"` in the file.

### Finding links and art

- **Netflix:** take the number from `netflix.com/title/<id>` and add both
  `nflx://www.netflix.com/title/<id>` and `https://www.netflix.com/title/<id>`.
- **Disney+:** open the title on disneyplus.com and copy the URL
  (`…/browse/entity-<uuid>` or `…/movies/<name>/<id>`). Remove the region part
  (`/en-gb`).
- **Apple TV app:** use the `https://tv.apple.com/...` link.
- **YouTube:** avoid. The tvOS app ignores deep links.
- **Art:** search the title on themoviedb.org → *Media → Backdrops* → open an
  image and swap `/original/` in its URL for `/w780/`.

Test each new title once on the real Apple TV.

## Build and run

Requirements: Xcode 16+, tvOS 18+ on the Apple TV, with the streaming apps
installed and signed in.

- **Simulator:** open `KidsTV.xcodeproj`, pick an Apple TV simulator, ⌘R.
  Streaming apps aren't installed in the simulator, so tapping a tile shows
  the "Ask a grown-up" message. That's expected.
- **Apple TV:** on the Apple TV go to Settings → Remote Apps and Devices →
  Remote App and Devices; in Xcode go to Window → Devices and Simulators and
  pair it. Pick it as the run destination, then ⌘R. A free Apple ID build
  expires after 7 days; a paid developer account lasts a year.

The project uses folder-synced groups, so new files in `KidsTV/` are picked
up automatically.

## Layout

```
KidsTV/
├── KidsTVApp.swift              App entry, image cache
├── Models/
│   ├── Show.swift               Catalog + show model (tolerant JSON decoding)
│   └── StreamingService.swift   Badge colors, app-home fallback URLs
├── Services/
│   ├── CatalogStore.swift       Cache → bundle → live GitHub catalog
│   └── LinkOpener.swift         Tries each link, reports failure
├── Views/
│   ├── DashboardView.swift      The grid + "couldn't open" alert
│   └── ShowTile.swift           Tile, artwork, title-card fallback
├── Data/shows.json              The catalog (edit this)
└── Assets.xcassets              App icon + top shelf
```

The live catalog URL is `CatalogStore.remoteURL`. Change it if the repo moves
or goes private (raw GitHub links only work for public repos).
