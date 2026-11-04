"""Builds WorldZoom/Data/world.json from Natural Earth (public domain).

Download these two files from
https://github.com/nvkelso/natural-earth-vector/tree/master/geojson
and run:  python3 tools/build_world_map.py <dir-with-the-geojson-files>

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
for f in json.load(open(SRC / "ne_50m_admin_0_countries.geojson"))["features"]:
    p = f["properties"]
    rings = rings_of(f["geometry"], 0.03)
    if not rings:
        continue
    name = p["NAME"]
    continent = "Australia" if name in AUSTRALIA_CONTINENT else p["CONTINENT"]
    center, radius = cap(rings)
    countries.append({"name": name, "continent": continent, "color": p["MAPCOLOR7"],
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
                   "center": center, "radius": radius, "rings": rings})

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps({
    "source": "Natural Earth 1:50m, public domain (naturalearthdata.com)",
    "countries": countries,
    "states": states,
}, separators=(",", ":")))
print(f"{len(countries)} countries, {len(states)} states -> {OUT} ({OUT.stat().st_size // 1024} KB)")
