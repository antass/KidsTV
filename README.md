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

---

# World Zoom (iPad)

A second app in this repo, for Charlie: learning the difference between
**continents, countries, states, and cities**. Everything is built on one
picture — places fit inside places, like boxes inside boxes — and every kind
of place always has the same color, icon, and word:

| Kind | Color | Icon |
|------|-------|------|
| Continent | purple | 🗺 map |
| Country | blue | 🚩 flag |
| State | orange | 🧩 puzzle piece |
| City | green | 🏙 buildings |

## The four screens

- **Zoom Out** — pick a city (Home/Boston, Orlando, Toronto, Tokyo, …) and
  start right there, then zoom out one step at a time: city → state/province →
  country → continent → Earth, on a political map drawn on a globe. Every box
  of the address stays colored on the map (continent purple, country blue,
  state orange, city green dot), the nested boxes light up the level you're
  on, and each step is read out loud. Ends with the whole address.
- **What Is It?** — a place name appears; tap Continent / Country / State /
  City. Every right answer shows the place inside its nest. Misses come back
  a few cards later. 10 cards a round, with a hint button.
- **Stack It** — the pieces of an address are jumbled; tap them biggest-first
  and they drop into the boxes.
- **Cheat Sheet** — the nest, what each word means, our own address, and the
  tricky ones (Australia, New York, Antarctica, Canada's provinces).

Read-aloud is on by default (toggle on the home screen); speaker buttons
always talk. Stars from both games are saved on the iPad.

## Add a place

Add one line to `WorldZoom/Models/Atlas.swift`. For a province or other
non-"state" piece, set `word: "Province"` and `tricky: true`. `parent` must be the name of a
bigger place already in the list; `zoom` is how high the map camera sits
(roughly: city 30,000, state 500,000–1,500,000, country 1,500,000–6,000,000).
Mark names that mean two things (`tricky: true`) so the quiz skips them. To
make it a Zoom Out destination, add its name to `Atlas.trips`. A state is
colored on the map when its name matches Natural Earth's (US, Canada, and
Australia are included); a country with a different Natural Earth name gets
`mapName:`.

## The map

Political borders only, from [Natural Earth](https://www.naturalearthdata.com)
(public domain), bundled as `WorldZoom/Data/world.json` and drawn by
`Views/PoliticalMap.swift`. No map service, so it works offline. To rebuild
the data (for example to add another country's states), download
`ne_50m_admin_0_countries.geojson` and `ne_50m_admin_1_states_provinces.geojson`
from github.com/nvkelso/natural-earth-vector and run
`python3 tools/build_world_map.py <folder>`.

## Build and run

Xcode 26+, iPadOS 18+ / macOS 15+. Same signing team as KidsTV; a free
Apple ID build expires after 7 days. Works fully offline.

- **iPad:** open `WorldZoom.xcodeproj`, plug in the iPad (or pick an iPad
  simulator), ⌘R.
- **Mac:** same project, pick **My Mac (Mac Catalyst)** as the run
  destination, ⌘R. It's the same code running as a native Mac app. To keep it,
  Product → Archive → Distribute App → Copy App, then drag `World Zoom.app`
  into Applications.

```
WorldZoom/
├── WorldZoomApp.swift
├── Models/
│   ├── PlaceKind.swift      The 4 kinds (+ Earth): colors, icons, kid definitions
│   └── Atlas.swift          Every place, and how they nest
├── Data/world.json          Natural Earth borders (built by tools/)
├── Services/Speaker.swift   Read-aloud
└── Views/
    ├── HomeView.swift
    ├── ZoomView.swift       Start at a city, zoom out
    ├── PoliticalMap.swift   Globe drawn from Natural Earth borders
    ├── SortGameView.swift   "What Is It?"
    ├── StackGameView.swift  "Stack It"
    ├── CheatSheetView.swift
    └── NestedBoxes.swift    The boxes-in-boxes view + shared buttons
```
