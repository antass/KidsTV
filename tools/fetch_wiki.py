"""Fetches short, kid-friendly descriptions for every place on the map.

Source: Simple English Wikipedia (written for children and English learners),
falling back to English Wikipedia. Text is CC BY-SA 4.0; every entry keeps its
article link so the app can credit it.

Run after tools/build_world_map.py:  python3 tools/fetch_wiki.py
Needs network access to simple.wikipedia.org, en.wikipedia.org, www.wikidata.org.
Output: WorldZoom/Data/wiki.json
"""
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WORLD = ROOT / "WorldZoom" / "Data" / "world.json"
OUT = ROOT / "WorldZoom" / "Data" / "wiki.json"
UA = "WorldZoomBuilder/1.0 (https://github.com/antass/KidsTV; kids geography app build script) python-urllib"

CONTINENT_TITLES = {
    "Africa": "Africa", "Asia": "Asia", "Europe": "Europe", "North America": "North America",
    "South America": "South America", "Australia": "Australia (continent)", "Antarctica": "Antarctica",
    "Oceania": "Oceania",
}
# Names that need an exact article (ambiguous or unusual on Wikipedia).
OVERRIDES = {
    "country:Georgia": "Georgia (country)",
    "state:Georgia": "Georgia (U.S. state)",
    "state:Victoria": "Victoria (state)",
    "state:North Dakota": "North Dakota",
    "country:Congo": "Republic of the Congo",
    "country:Central African Rep.": "Central African Republic",
    "country:Bosnia and Herz.": "Bosnia and Herzegovina",
    "country:Antigua and Barb.": "Antigua and Barbuda",
    "country:U.S. Virgin Is.": "United States Virgin Islands",
    "country:Pitcairn Is.": "Pitcairn Islands",
    "country:St. Pierre and Miquelon": "Saint Pierre and Miquelon",
    "country:Wallis and Futuna Is.": "Wallis and Futuna",
    "country:St-Martin": "Collectivity of Saint Martin",
    "country:St-Barthélemy": "Saint Barthélemy",
    "country:Fr. Polynesia": "French Polynesia",
    "country:Fr. S. Antarctic Lands": "French Southern and Antarctic Lands",
    "country:Faeroe Is.": "Faroe Islands",
    "country:N. Cyprus": "Northern Cyprus",
    "country:Indian Ocean Ter.": "British Indian Ocean Territory",
    "country:Heard I. and McDonald Is.": "Heard Island and McDonald Islands",
    "city:Saint John's": "St. John's, Antigua and Barbuda",
}
# Cities the app teaches that aren't national capitals.
APP_CITIES = {
    "Boston": "Boston", "Orlando": "Orlando, Florida", "Miami": "Miami", "Los Angeles": "Los Angeles",
    "Houston": "Houston", "New York City": "New York City", "Chicago": "Chicago", "Honolulu": "Honolulu",
    "Sydney": "Sydney", "Toronto": "Toronto", "Rio de Janeiro": "Rio de Janeiro", "Mumbai": "Mumbai",
}


def get_json(url):
    for attempt in range(6):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=20) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return None
            if e.code == 429 or e.code >= 500:
                wait = e.headers.get("Retry-After")
                time.sleep(float(wait) if wait and wait.isdigit() else 3 * 2 ** attempt)
                continue
            return None
        except (urllib.error.URLError, TimeoutError):
            time.sleep(2 ** attempt)
    return None


def sitelinks(qids):
    """Wikidata Q-id -> {'simplewiki': title, 'enwiki': title}."""
    out = {}
    qids = [q for q in qids if q]
    for i in range(0, len(qids), 50):
        batch = "|".join(qids[i:i + 50])
        data = get_json("https://www.wikidata.org/w/api.php?action=wbgetentities&props=sitelinks"
                        f"&sitefilter=simplewiki|enwiki&format=json&ids={urllib.parse.quote(batch)}") or {}
        for qid, ent in data.get("entities", {}).items():
            links = ent.get("sitelinks", {})
            out[qid] = {k: v["title"] for k, v in links.items()}
    return out


def trim(text, limit=430):
    text = re.sub(r"\s+", " ", text or "").strip()
    sentences = re.split(r"(?<=[.!?])\s+", text)
    out = ""
    for s in sentences:
        if out and len(out) + len(s) + 1 > limit:
            break
        out = (out + " " + s).strip()
        if len(out) > 120 and out.count(". ") >= 2:
            break
    return out


def summary(titles):
    """First usable summary among (wiki, title) candidates."""
    for wiki, title in titles:
        if not title:
            continue
        data = get_json(f"https://{wiki}.wikipedia.org/api/rest_v1/page/summary/"
                        + urllib.parse.quote(title.replace(" ", "_"), safe=""))
        if not data or data.get("type") == "disambiguation" or not data.get("extract"):
            continue
        return {
            "title": data.get("title", title),
            "text": trim(data["extract"]),
            "url": data.get("content_urls", {}).get("desktop", {}).get("page", ""),
            "source": "Simple English Wikipedia" if wiki == "simple" else "Wikipedia",
        }
    return None


def main():
    world = json.loads(WORLD.read_text())
    links = sitelinks([c.get("wikidata") for c in world["countries"]] + [s.get("wikidata") for s in world["states"]])

    def by_qid(item):
        l = links.get(item.get("wikidata"), {})
        return [("simple", l.get("simplewiki")), ("en", l.get("enwiki")),
                ("simple", item["name"]), ("en", item["name"])]

    jobs = {}
    for name, title in CONTINENT_TITLES.items():
        jobs[f"continent:{name}"] = [("simple", title), ("en", title)]
    for c in world["countries"]:
        jobs[f"country:{c['name']}"] = by_qid(c)
    for s in world["states"]:
        jobs[f"state:{s['name']}"] = by_qid(s)
    country_title = {c["name"]: (links.get(c.get("wikidata"), {}).get("enwiki") or c["name"]) for c in world["countries"]}
    for cap in world["capitals"]:
        alt = f"{cap['name']}, {country_title.get(cap['country'], cap['country'])}"
        jobs[f"city:{cap['name']}"] = [("simple", cap["name"]), ("en", cap["name"]), ("simple", alt), ("en", alt)]
    for name, title in APP_CITIES.items():
        jobs[f"city:{name}"] = [("simple", title), ("en", title)]

    for key, title in OVERRIDES.items():
        jobs[key] = [("simple", title), ("en", title)]

    # Resume: keep entries already from Simple English Wikipedia; redo the rest.
    items = {}
    if OUT.exists():
        old = json.loads(OUT.read_text()).get("items", {})
        items = {k: v for k, v in old.items() if k in jobs and v.get("source") == "Simple English Wikipedia"}
    keys = [k for k in jobs if k not in items]
    print(f"{len(items)} kept, fetching {len(keys)}")
    with ThreadPoolExecutor(max_workers=2 if items else 4) as pool:
        results = list(pool.map(lambda k: summary(jobs[k]), keys))
    items.update({k: v for k, v in zip(keys, results) if v})
    missing = [k for k in jobs if k not in items]

    OUT.write_text(json.dumps({
        "license": "Text from Simple English Wikipedia and Wikipedia, CC BY-SA 4.0",
        "items": items,
    }, ensure_ascii=False, separators=(",", ":")))
    print(f"{len(items)} summaries -> {OUT} ({OUT.stat().st_size // 1024} KB); missing {len(missing)}")
    if missing:
        print("missing:", ", ".join(missing[:40]), file=sys.stderr)


if __name__ == "__main__":
    main()
