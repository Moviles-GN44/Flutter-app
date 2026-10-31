import argparse
import json
import random
import statistics
import time
import urllib.request
import webbrowser
from collections import Counter
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
GOOGLE_SERVICES = HERE.parent / "android" / "app" / "google-services.json"

KOTLIN_EVENTS = [
    "samuel_bq_filter_session",
    "karin_bq_menu_inspection",
    "qr_review_submission",
    "karin_bq_group_suggestion",
    "bq_individual_search",
    "karin_bq_individual_search",
    "samuel_bq_building_filter",
]
FLUTTER_EVENTS = [
    "map_load_completed",
    "map_load_abandoned",
    "restaurant_comparison_criterion",
    "review_started",
    "review_published",
    "filter_session_completed",
    "filter_applied",
]

RESTAURANT_NAMES = {
    "el_toro_rgd": "El Toro (RGD)",
    "one_burrito_ml": "One Burrito (ML)",
    "one_burrito_rgd": "One Burrito (RGD)",
    "burger_play_rgd": "Burger Play (RGD)",
    "burger_play_sd": "Burger Play (SD)",
    "la_cabra_sanduchera_rgd": "La Cabra Sanduchera",
    "la_liebre_franco": "La Liebre (Franco)",
}
CRITERIA = ["price", "distance", "waiting_time", "menu", "dietary_preferences"]
FILTER_TYPES = ["category", "walking_time", "price", "dietary", "payment"]
RESTRICTIONS = ["vegan", "gluten_free", "lactose_free"]
METHODS = ["qr", "manual"]
SECONDS_BUCKETS = [(5, "< 5s"), (10, "5-10s"), (20, "10-20s"), (None, "> 20s")]
LOAD_BUCKETS = [(1, "< 1s"), (2, "1-2s"), (5, "2-5s"), (None, "> 5s")]


def firebase_config():
    config = json.loads(GOOGLE_SERVICES.read_text(encoding="utf-8"))
    project_id = config["project_info"]["project_id"]
    api_key = config["client"][0]["api_key"][0]["current_key"]
    return project_id, api_key


def decode(value):
    if "mapValue" in value:
        fields = value["mapValue"].get("fields", {})
        return {name: decode(inner) for name, inner in fields.items()}
    if "arrayValue" in value:
        return [decode(inner) for inner in value["arrayValue"].get("values", [])]
    if "integerValue" in value:
        return int(value["integerValue"])
    if "doubleValue" in value:
        return float(value["doubleValue"])
    for kind in ("stringValue", "booleanValue", "timestampValue"):
        if kind in value:
            return value[kind]
    return None


def fetch_events():
    project_id, api_key = firebase_config()
    url = (
        f"https://firestore.googleapis.com/v1/projects/{project_id}"
        f"/databases/(default)/documents:runQuery?key={api_key}"
    )
    names = KOTLIN_EVENTS + FLUTTER_EVENTS
    query = {
        "structuredQuery": {
            "from": [{"collectionId": "telemetry_events"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "eventName"},
                    "op": "IN",
                    "value": {
                        "arrayValue": {"values": [{"stringValue": n} for n in names]}
                    },
                }
            },
        }
    }
    request = urllib.request.Request(
        url,
        data=json.dumps(query).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        rows = json.load(response)
    return [decode({"mapValue": row["document"]}) for row in rows if "document" in row]


def params(event):
    value = event.get("params")
    return value if isinstance(value, dict) else {}


def named(events, *names):
    return [e for e in events if e.get("eventName") in names]


def average(values):
    return round(sum(values) / len(values), 1) if values else "N/A"


def percent(part, total):
    return round(part / total * 100, 1) if total else "N/A"


def buckets(values, limits):
    counts = {label: 0 for _, label in limits}
    for value in values:
        for limit, label in limits:
            if limit is None or value < limit:
                counts[label] += 1
                break
    return counts


def number(value):
    return float(value) if isinstance(value, (int, float)) else None


def seconds(events, key, factor=1):
    values = [number(params(e).get(key)) for e in events]
    return [v / factor for v in values if v is not None]


def bq6_samuel(events):
    sessions = named(events, "samuel_bq_filter_session")
    durations = seconds(sessions, "duration_sec")
    buildings = Counter({b: 0 for b in ["ML", "RGD", "Franco", "SD", "C", "W"]})
    buildings.update(params(e).get("building", "ML") for e in sessions)
    return {
        "sessions": len(sessions),
        "avg_duration": average(durations),
        "duration_buckets": buckets(durations, SECONDS_BUCKETS),
        "buildings": dict(buildings),
        "dietary": {
            "Vegano": sum(params(e).get("is_vegan") is True for e in sessions),
            "Sin gluten": sum(params(e).get("is_gluten_free") is True for e in sessions),
        },
    }


def bq4_karin(events):
    inspections = named(events, "karin_bq_menu_inspection")
    checked = sum(bool(params(e).get("checked_photos")) for e in inspections)
    restaurants = Counter(
        RESTAURANT_NAMES.get(rid, rid)
        for rid in (params(e).get("restaurant_id", "general") for e in inspections)
    )
    return {
        "inspection_rate": percent(checked, len(inspections)),
        "checked": checked,
        "not_checked": len(inspections) - checked,
        "restaurants": dict(restaurants.most_common(8)),
    }


def bq8_karin(events):
    groups = named(events, "karin_bq_group_suggestion")
    individual = len(named(events, "bq_individual_search", "karin_bq_individual_search"))
    sizes = [number(params(e).get("group_size")) for e in groups]
    return {
        "group": len(groups),
        "individual": individual,
        "group_pct": percent(len(groups), len(groups) + individual),
        "avg_group_size": average([s for s in sizes if s is not None]),
    }


def bq10_samuel(events):
    filters = named(events, "samuel_bq_building_filter")
    building = [e for e in filters if params(e).get("filter_mode") == "CAMPUS_BUILDING"]
    generic = sum(params(e).get("filter_mode") == "GENERIC_SEARCH" for e in filters)
    return {
        "building": len(building),
        "generic": generic,
        "building_pct": percent(len(building), len(building) + generic),
        "buildings": dict(Counter(params(e).get("building", "NONE") for e in building).most_common(6)),
    }


def qr_reviews(events):
    reviews = named(events, "qr_review_submission")
    completed = [e for e in reviews if params(e).get("is_completed")]
    ratings = [number(params(e).get("rating")) or 0 for e in completed]
    ratings = [int(r) for r in ratings if 1 <= r <= 5]
    return {
        "avg_rating": average(ratings),
        "completed": len(completed),
        "cancelled": len(reviews) - len(completed),
        "ratings": {str(star): ratings.count(star) for star in range(1, 6)},
    }


def bq2_felipe(events):
    loaded = named(events, "map_load_completed")
    abandoned = named(events, "map_load_abandoned")
    load_times = seconds(loaded, "durationMs", 1000)
    cache = seconds([e for e in loaded if params(e).get("fromCache") is True], "durationMs", 1000)
    server = seconds([e for e in loaded if params(e).get("fromCache") is False], "durationMs", 1000)
    return {
        "loads": len(loaded),
        "abandoned": len(abandoned),
        "avg_load": average(load_times),
        "median_load": round(statistics.median(load_times), 1) if load_times else "N/A",
        "abandon_pct": percent(len(abandoned), len(loaded) + len(abandoned)),
        "avg_wait_abandoned": average(seconds(abandoned, "durationMs", 1000)),
        "avg_cache": average(cache),
        "avg_server": average(server),
        "load_buckets": buckets(load_times, LOAD_BUCKETS),
    }


def bq3_catalina(events):
    counts = Counter({c: 0 for c in CRITERIA})
    counts.update(
        c
        for c in (params(e).get("criterion") for e in named(events, "restaurant_comparison_criterion"))
        if c in CRITERIA
    )
    total = sum(counts.values())
    return {
        "total": total,
        "counts": dict(counts),
        "top": max(counts, key=counts.get) if total else None,
        "top_pct": percent(max(counts.values()), total),
    }


def bq5_felipe(events):
    totals = {}
    for method in METHODS:
        started = sum(params(e).get("method") == method for e in named(events, "review_started"))
        published = sum(params(e).get("method") == method for e in named(events, "review_published"))
        totals[method] = {
            "started": started,
            "published": published,
            "conversion": percent(published, started),
        }
    return totals


def bq6_juanjo(events):
    sessions = named(events, "filter_session_completed")
    durations = seconds(sessions, "durationMs", 1000)
    suggested = [e for e in sessions if params(e).get("usedSuggestion") is True]
    manual = [e for e in sessions if params(e).get("usedSuggestion") is False]
    return {
        "sessions": len(sessions),
        "avg_duration": average(durations),
        "duration_buckets": buckets(durations, SECONDS_BUCKETS),
        "with_suggestion": average(seconds(suggested, "durationMs", 1000)),
        "without_suggestion": average(seconds(manual, "durationMs", 1000)),
    }


def bq9_juanjo(events):
    applied = [e for e in named(events, "filter_applied") if params(e).get("filterType") in FILTER_TYPES]
    types = Counter({t: 0 for t in FILTER_TYPES})
    types.update(params(e)["filterType"] for e in applied)
    restrictions = Counter({r: 0 for r in RESTRICTIONS})
    restrictions.update(
        params(e).get("value")
        for e in applied
        if params(e)["filterType"] == "dietary" and params(e).get("value") in RESTRICTIONS
    )
    return {
        "uses": len(applied),
        "types": dict(types),
        "restrictions": dict(restrictions),
        "dietary_pct": percent(types["dietary"], len(applied)),
    }


def calculate_metrics(events):
    flutter = sum(e.get("platform") == "Flutter" for e in events)
    latest = sorted(events, key=lambda e: number(e.get("timestamp")) or 0, reverse=True)
    return {
        "generated_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "summary": {"total": len(events), "flutter": flutter, "kotlin": len(events) - flutter},
        "bq2_felipe": bq2_felipe(events),
        "bq8_karin": bq8_karin(events),
        "bq10_samuel": bq10_samuel(events),
        "bq6_samuel": bq6_samuel(events),
        "bq4_karin": bq4_karin(events),
        "qr_reviews": qr_reviews(events),
        "bq3_catalina": bq3_catalina(events),
        "bq5_felipe": bq5_felipe(events),
        "bq6_juanjo": bq6_juanjo(events),
        "bq9_juanjo": bq9_juanjo(events),
        "raw_events": [
            {k: e.get(k) for k in ("timestamp", "eventName", "platform", "params")}
            for e in latest[:30]
        ],
    }


def demo_events():
    now = int(time.time() * 1000)
    restaurants = list(RESTAURANT_NAMES)

    def event(name, platform, values):
        timestamp = now - random.randint(0, 6 * 24 * 3600 * 1000)
        return {"eventName": name, "timestamp": timestamp, "platform": platform, "params": values}

    events = []
    for _ in range(60):
        from_cache = random.random() < 0.4
        load = random.randint(150, 900) if from_cache else random.randint(700, 6500)
        events.append(event("map_load_completed", "Flutter", {"durationMs": load, "fromCache": from_cache}))
    for _ in range(9):
        events.append(event("map_load_abandoned", "Flutter", {"durationMs": random.randint(2000, 9000)}))
    for _ in range(80):
        criterion = random.choices(CRITERIA, weights=[3, 6, 2, 2, 1])[0]
        events.append(event("restaurant_comparison_criterion", "Flutter", {"criterion": criterion}))
    for _ in range(50):
        method = random.choice(METHODS)
        events.append(event("review_started", "Flutter", {"method": method}))
        if random.random() < (0.8 if method == "qr" else 0.45):
            events.append(event("review_published", "Flutter", {"method": method}))
    for _ in range(40):
        events.append(
            event(
                "filter_session_completed",
                "Flutter",
                {"durationMs": random.randint(2000, 30000), "usedSuggestion": random.random() < 0.35},
            )
        )
    for _ in range(70):
        filter_type = random.choices(FILTER_TYPES, weights=[4, 3, 3, 2, 1])[0]
        value = random.choice(RESTRICTIONS) if filter_type == "dietary" else "any"
        events.append(event("filter_applied", "Flutter", {"filterType": filter_type, "value": value}))
    for _ in range(35):
        events.append(
            event(
                "samuel_bq_filter_session",
                "Android-Kotlin",
                {
                    "duration_sec": round(random.uniform(2, 30), 1),
                    "building": random.choice(["ML", "RGD", "Franco", "SD", "C", "W"]),
                    "is_vegan": random.random() < 0.3,
                    "is_gluten_free": random.random() < 0.2,
                },
            )
        )
    for _ in range(45):
        events.append(
            event(
                "karin_bq_menu_inspection",
                "Android-Kotlin",
                {"restaurant_id": random.choice(restaurants), "checked_photos": random.random() < 0.6},
            )
        )
    for _ in range(25):
        completed = random.random() < 0.75
        events.append(
            event(
                "qr_review_submission",
                "Android-Kotlin",
                {"rating": random.randint(1, 5) if completed else 0, "is_completed": completed},
            )
        )
    for _ in range(15):
        events.append(event("karin_bq_group_suggestion", "Android-Kotlin", {"group_size": random.randint(2, 6)}))
    for _ in range(40):
        events.append(event("karin_bq_individual_search", "Android-Kotlin", {}))
    for _ in range(50):
        mode = "CAMPUS_BUILDING" if random.random() < 0.8 else "GENERIC_SEARCH"
        building = random.choice(["ML", "RGD", "Franco", "SD", "C", "W"]) if mode == "CAMPUS_BUILDING" else "NONE"
        events.append(event("samuel_bq_building_filter", "Android-Kotlin", {"filter_mode": mode, "building": building}))
    return events


def make_handler(load):
    page = (HERE / "dashboard.html").read_bytes()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path == "/api/stats":
                try:
                    body, status = json.dumps(calculate_metrics(load())).encode(), 200
                except Exception as error:
                    body, status = json.dumps({"error": str(error)}).encode(), 500
                self._send(status, "application/json", body)
            elif self.path in ("/", "/index.html"):
                self._send(200, "text/html; charset=utf-8", page)
            else:
                self._send(404, "text/plain", b"Not found")

        def _send(self, status, content_type, body):
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *args):
            pass

    return Handler


def main():
    parser = argparse.ArgumentParser(description="Uniandes Food unified analytics dashboard")
    parser.add_argument("--demo", action="store_true", help="use sample data instead of Firestore")
    parser.add_argument("--port", type=int, default=5000)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()

    sample = demo_events() if args.demo else None
    load = (lambda: sample) if args.demo else fetch_events

    url = f"http://localhost:{args.port}"
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(load))
    print(f"Uniandes Food dashboard en {url}  (Ctrl+C para salir)")
    if not args.no_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
