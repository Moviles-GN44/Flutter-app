"""Local analytics dashboard for the business questions.

BQ3: which criterion do students consult the most when comparing
restaurants (price, distance, waiting time, menu, dietary preferences)?

BQ5: how many students who start a review end up publishing it, and does
verifying the visit with the QR code change that?

Pipeline:
  Flutter app (HomeViewModel, RestaurantDetailScreen, WriteReviewViewModel)
    -> TelemetryService.trackComparisonCriterion() / trackReviewEvent()
    -> Firestore `telemetry_events`
    -> this script (aggregate_bq3 / aggregate_bq5)
    -> http://localhost:8000

Reads Firestore through its REST API with the public API key from
android/app/google-services.json, so it needs no credentials and no
packages beyond the standard library.

Usage:
  python analytics/dashboard.py            # reads Firestore
  python analytics/dashboard.py --demo     # sample data, offline
"""

import argparse
import json
import random
import time
import urllib.request
import webbrowser
from collections import defaultdict
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).parent
GOOGLE_SERVICES = HERE.parent / "android" / "app" / "google-services.json"
COMPARISON_EVENT = "restaurant_comparison_criterion"
REVIEW_EVENTS = ["review_started", "review_published"]
METHODS = ["qr", "manual"]
# Same criteria as BQ3AnalyticsService in lib/services/bq3_analytics_service.dart.
CRITERIA = ["price", "distance", "waiting_time", "menu", "dietary_preferences"]


def firebase_config():
    """Project id and public API key from the Android Firebase config."""
    config = json.loads(GOOGLE_SERVICES.read_text(encoding="utf-8"))
    project_id = config["project_info"]["project_id"]
    api_key = config["client"][0]["api_key"][0]["current_key"]
    return project_id, api_key


def decode(value):
    """Converts a Firestore REST value into a plain Python value."""
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


def fetch_events(event_names):
    project_id, api_key = firebase_config()
    url = (
        f"https://firestore.googleapis.com/v1/projects/{project_id}"
        f"/databases/(default)/documents:runQuery?key={api_key}"
    )
    query = {
        "structuredQuery": {
            "from": [{"collectionId": "telemetry_events"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "eventName"},
                    "op": "IN",
                    "value": {
                        "arrayValue": {
                            "values": [{"stringValue": e} for e in event_names]
                        }
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
    return [
        decode({"mapValue": row["document"]})
        for row in rows
        if "document" in row
    ]


def demo_events():
    restaurants = ["el-corral", "wok", "crepes", "subway", "la-tienda"]
    now = int(time.time() * 1000)
    day = 24 * 60 * 60 * 1000
    events = []
    for _ in range(140):
        method = random.choice(METHODS)
        restaurant = random.choice(restaurants)
        timestamp = now - random.randint(0, 13) * day
        params = {"method": method, "restaurantId": restaurant}
        events.append(
            {"eventName": "review_started", "timestamp": timestamp, "params": params}
        )
        if random.random() < (0.8 if method == "qr" else 0.45):
            events.append(
                {
                    "eventName": "review_published",
                    "timestamp": timestamp + 60_000,
                    "params": params,
                }
            )
    for _ in range(90):
        events.append(
            {
                "eventName": COMPARISON_EVENT,
                "timestamp": now - random.randint(0, 13) * day,
                "params": {
                    "criterion": random.choices(CRITERIA, weights=[3, 6, 2, 2, 1])[0],
                    "restaurantId": random.choice(restaurants),
                    "userId": f"user-{random.randint(1, 25)}",
                },
            }
        )
    return events


def aggregate_bq3(events):
    """Turns raw comparison events into the BQ3 answer."""
    counts = {criterion: 0 for criterion in CRITERIA}
    by_restaurant = defaultdict(int)
    users = set()

    for event in events:
        if event.get("eventName") != COMPARISON_EVENT:
            continue
        params = event.get("params")
        if not isinstance(params, dict):
            continue
        criterion = params.get("criterion")
        if criterion not in counts:
            continue

        counts[criterion] += 1
        by_restaurant[params.get("restaurantId") or "unknown"] += 1
        if params.get("userId"):
            users.add(params["userId"])

    total = sum(counts.values())
    return {
        "generatedAt": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "total": total,
        "uniqueUsers": len(users),
        "counts": counts,
        "percentages": {
            criterion: round(count / total * 100, 1) if total else 0
            for criterion, count in counts.items()
        },
        "mostConsulted": max(counts, key=counts.get) if total else None,
        "byRestaurant": dict(
            sorted(by_restaurant.items(), key=lambda item: -item[1])[:8]
        ),
    }


def aggregate_bq5(events):
    """Turns raw review events into the BQ5 answer."""
    totals = {m: {"started": 0, "published": 0} for m in METHODS}
    by_restaurant = defaultdict(lambda: {m: 0 for m in METHODS})
    by_day = defaultdict(lambda: {m: 0 for m in METHODS})

    for event in events:
        if event.get("eventName") not in REVIEW_EVENTS:
            continue
        params = event.get("params")
        if not isinstance(params, dict):
            continue
        method = params.get("method")
        if method not in totals:
            continue

        if event.get("eventName") == "review_started":
            totals[method]["started"] += 1
        elif event.get("eventName") == "review_published":
            totals[method]["published"] += 1
            by_restaurant[params.get("restaurantId") or "unknown"][method] += 1
            timestamp = event.get("timestamp")
            if isinstance(timestamp, (int, float)):
                date = datetime.fromtimestamp(timestamp / 1000).strftime("%Y-%m-%d")
                by_day[date][method] += 1

    for counts in totals.values():
        started = counts["started"]
        counts["conversion"] = (
            round(counts["published"] / started * 100, 1) if started else 0
        )

    published = sum(c["published"] for c in totals.values())
    return {
        "generatedAt": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "totalEvents": len(events),
        "totals": totals,
        "qrShare": round(totals["qr"]["published"] / published * 100, 1)
        if published
        else 0,
        "byRestaurant": dict(
            sorted(by_restaurant.items(), key=lambda item: -sum(item[1].values()))
        ),
        "byDay": dict(sorted(by_day.items())),
    }


API = {
    "/api/bq3": ([COMPARISON_EVENT], aggregate_bq3),
    "/api/bq5": (REVIEW_EVENTS, aggregate_bq5),
}


def make_handler(load):
    page = (HERE / "dashboard.html").read_bytes()

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path in API:
                event_names, aggregate = API[self.path]
                try:
                    result = aggregate(load(event_names))
                    body, status = json.dumps(result).encode(), 200
                except Exception as error:  # surface Firestore errors in the page
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
    parser = argparse.ArgumentParser(description="BQ3 + BQ5 analytics dashboard")
    parser.add_argument("--demo", action="store_true", help="use sample data")
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--no-browser", action="store_true")
    args = parser.parse_args()

    if args.demo:
        sample = demo_events()
        load = lambda names: [e for e in sample if e["eventName"] in names]
    else:
        load = fetch_events

    url = f"http://localhost:{args.port}"
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(load))
    print(f"Dashboard BQ3 + BQ5 en {url}  (Ctrl+C para salir)")
    if not args.no_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
