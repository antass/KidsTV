"""Builds WorldZoom/Data/world.json from Natural Earth (public domain).

Download these three files from
https://github.com/nvkelso/natural-earth-vector/tree/master/geojson
(ne_50m_admin_0_countries, ne_50m_admin_1_states_provinces,
ne_50m_populated_places_simple) and run:  python3 tools/build_world_map.py <dir-with-the-geojson-files>

Optional: with shapely installed (pip install shapely), also merges the
countries into one outline per continent for the zoomed-out globe.

Output: political borders only. Countries (with continent) and the states /
provinces of the countries the app talks about, simplified to about 1 km.
"""
import json
import math
import sys
from pathlib import Path

SRC = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
OUT = Path(__file__).resolve().parent.parent / "WorldZoom" / "Data" / "world.json"

STATE_COUNTRIES = {"United States of America", "Canada", "Australia"}  # states / provinces kept
# Natural Earth files Australia under "Oceania"; the app teaches 7 continents
# with Australia as one, so the Australia continent is Australia + New Guinea.
AUSTRALIA_CONTINENT = {"Australia", "Papua New Guinea"}


try:
    from shapely.geometry import MultiPolygon, Polygon, mapping, shape
    from shapely.ops import unary_union
    HAVE_SHAPELY = True
except ImportError:
    HAVE_SHAPELY = False

# Natural Earth files each country under one continent. These split the ones
# that sit on two, so continents come out right (Siberia is Asia, not Europe).
# Line between Europe and Asia across Russia: Ural Mountains, Ural River, Caspian.
URAL_EUROPE_SIDE = [(-30, 85), (68.5, 85), (66.5, 70), (65, 68.5), (60, 65), (59.5, 61), (59.5, 57),
                    (59, 54), (58.5, 51), (51.5, 51), (51.9, 47), (49, 42), (40, 40), (-30, 40)]
# Turkey west of the Bosporus, Sea of Marmara and Dardanelles (Thrace) is Europe.
THRACE = [(20, 45), (29.3, 45), (29.1, 41.4), (28.9, 40.9), (27, 40.55), (26.5, 40.25), (26.15, 40.0),
          (25.5, 39.8), (20, 39.8)]
# Far-away islands and territories of European countries: (lon range, lat range, continent).
OVERSEAS = [
    ((-62, -50), (1, 7), "South America"),    # French Guiana
    ((-90, -55), (10, 20), "North America"),  # Martinique, Guadeloupe, Dutch Caribbean
    ((-19, -13), (27, 30), "Africa"),         # Canary Islands
    ((-18, -16), (32, 34), "Africa"),         # Madeira
    ((40, 60), (-26, -10), "Africa"),         # Réunion, Mayotte
]


def polygons_only(g):
    if g.is_empty:
        return None
    if g.geom_type in ("Polygon", "MultiPolygon"):
        return g
    polys = [x for x in getattr(g, "geoms", []) if x.geom_type == "Polygon"]
    return MultiPolygon(polys) if polys else None


def split_by_continent(name, base, geom):
    """[(continent, geojson geometry)] for one country."""
    if not HAVE_SHAPELY:
        return [(base, geom)]
    g = shape(geom).buffer(0)
    if name in ("Russia", "Turkey"):
        cut = Polygon(URAL_EUROPE_SIDE if name == "Russia" else THRACE)
        parts = [("Europe", g.intersection(cut)), ("Asia", g.difference(cut))]
    elif base == "Europe":
        groups = {}
        for poly in (list(g.geoms) if g.geom_type == "MultiPolygon" else [g]):
            pt = poly.representative_point()
            cont = next((c for (x0, x1), (y0, y1), c in OVERSEAS if x0 <= pt.x <= x1 and y0 <= pt.y <= y1), base)
            groups.setdefault(cont, []).append(poly)
        parts = [(c, unary_union(v)) for c, v in groups.items()]
    else:
        return [(base, geom)]
    out = []
    for cont, part in parts:
        part = polygons_only(part)
        if part is not None:
            out.append((cont, mapping(part)))
    return out


def rdp(points, eps):
    """Douglas-Peucker line simplification."""
    if len(points) < 3:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        a, b = stack.pop()
        ax, ay = points[a]
        bx, by = points[b]
        dx, dy = bx - ax, by - ay
        norm = math.hypot(dx, dy)
        best, idx = 0.0, None
        for i in range(a + 1, b):
            px, py = points[i]
            # Closed rings start and end on the same point: measure from it.
            d = (abs(dy * px - dx * py + bx * ay - by * ax) / norm) if norm > 1e-9 else math.hypot(px - ax, py - ay)
            if d > best:
                best, idx = d, i
        if idx is not None and best > eps:
            keep[idx] = True
            stack += [(a, idx), (idx, b)]
    return [p for p, k in zip(points, keep) if k]


def rings_of(geom, eps):
    polys = geom["coordinates"] if geom["type"] == "MultiPolygon" else [geom["coordinates"]]
    out = []
    for poly in polys:
        for ring in poly:
            simple = rdp(ring, eps)
            pts = []
            for x, y in simple:
                p = [round(x, 2), round(y, 2)]
                if not pts or pts[-1] != p:
                    pts.append(p)
            if len(pts) >= 4:
                out.append(pts)
    return out


def cap(rings):
    """Center (lon, lat) and angular radius (degrees) of a bounding cap."""
    pts = [p for r in rings for p in r]
    vec = [0.0, 0.0, 0.0]
    for lon, lat in pts:
        lo, la = math.radians(lon), math.radians(lat)
        vec[0] += math.cos(la) * math.cos(lo)
        vec[1] += math.cos(la) * math.sin(lo)
        vec[2] += math.sin(la)
    n = math.sqrt(sum(v * v for v in vec)) or 1
    vec = [v / n for v in vec]
    radius = 0.0
    for lon, lat in pts:
        lo, la = math.radians(lon), math.radians(lat)
        dot = vec[0] * math.cos(la) * math.cos(lo) + vec[1] * math.cos(la) * math.sin(lo) + vec[2] * math.sin(la)
        radius = max(radius, math.degrees(math.acos(max(-1, min(1, dot)))))
    if n < 1e-6 or radius > 89:  # e.g. Antarctica: treat as always potentially visible
        return [0, 0], 180
    return [round(math.degrees(math.atan2(vec[1], vec[0])), 2), round(math.degrees(math.asin(vec[2])), 2)], round(radius, 2)


countries = []
by_continent = {}
for f in json.load(open(SRC / "ne_50m_admin_0_countries.geojson"))["features"]:
    p = f["properties"]
    name = p["NAME"]
    base = "Australia" if name in AUSTRALIA_CONTINENT else p["CONTINENT"]
    parts = split_by_continent(name, base, f["geometry"])
    iso = p["ISO_A2_EH"] if p["ISO_A2_EH"] not in (None, "-99") else ""
    # Russia and Turkey really sit on two continents; overseas islands don't change
    # which continent a country "is in".
    all_continents = sorted({c for c, _ in parts}, key=lambda c: (c != base, c)) if name in ("Russia", "Turkey") else [base]
    # One entry per continent piece; "main" is the piece on the country's home continent.
    for continent, geom in parts:
        rings = rings_of(geom, 0.03)
        if not rings:
            continue
        if continent != "Seven seas (open ocean)":
            by_continent.setdefault(continent, []).append(geom)
        center, radius = cap(rings)
        countries.append({"name": name, "continent": continent, "continents": all_continents,
                          "main": continent == base, "color": p["MAPCOLOR7"], "iso": iso,
                          "a3": p["ADM0_A3"], "wikidata": p.get("WIKIDATAID") or "",
                          "center": center, "radius": radius, "rings": rings})

states = []
for f in json.load(open(SRC / "ne_50m_admin_1_states_provinces.geojson"))["features"]:
    p = f["properties"]
    if p["admin"] not in STATE_COUNTRIES:
        continue
    rings = rings_of(f["geometry"], 0.02)
    if not rings:
        continue
    center, radius = cap(rings)
    states.append({"name": p["name"], "country": p["admin"], "color": 0,
                   "word": "Province" if p["admin"] == "Canada" else "State",
                   "wikidata": p.get("wikidataid") or "",
                   "center": center, "radius": radius, "rings": rings})

# National capitals, matched to countries by their 3-letter code.
by_a3 = {c["a3"]: c["name"] for c in countries if c["main"]}
capitals = []
for f in json.load(open(SRC / "ne_50m_populated_places_simple.geojson"))["features"]:
    p = f["properties"]
    if p["featurecla"] != "Admin-0 capital" or p["adm0_a3"] not in by_a3:
        continue
    capitals.append({"name": " ".join(p["name"].split()), "country": by_a3[p["adm0_a3"]],
                     "lon": round(p["longitude"], 3), "lat": round(p["latitude"], 3)})

continents = []
try:
    if not HAVE_SHAPELY:
        raise ImportError
    for name, geoms in sorted(by_continent.items()):
        merged = unary_union([shape(g).buffer(0) for g in geoms]).buffer(0.02).buffer(-0.02)
        geom = mapping(merged.simplify(0.04))
        rings = rings_of(geom, 0.0) if geom["type"] in ("Polygon", "MultiPolygon") else []
        if rings:
            center, radius = cap(rings)
            continents.append({"name": name, "color": 0, "center": center, "radius": radius, "rings": rings})
except ImportError:
    print("shapely not installed: skipping continent outlines")

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps({
    "source": "Natural Earth 1:50m, public domain (naturalearthdata.com)",
    "countries": countries,
    "states": states,
    "continents": continents,
    "capitals": capitals,
}, separators=(",", ":")))
print(f"{len(countries)} countries, {len(states)} states, {len(continents)} continents, {len(capitals)} capitals -> {OUT} ({OUT.stat().st_size // 1024} KB)")
