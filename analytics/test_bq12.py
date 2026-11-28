
import unittest

from dashboard import bq12_catalina


def filter_event(apply_id, filter_type, value, platform="Flutter"):
    return {
        "eventName": "filter_applied",
        "platform": platform,
        "params": {
            "applyId": apply_id,
            "filterType": filter_type,
            "value": value,
            "userId": "test-user",
        },
    }


class TestBQ12(unittest.TestCase):

    def setUp(self):
        self.restaurants = [
            {
                "category": "Fast Food",
                "isVeganFriendly": True,
                "isGlutenFreeFriendly": False,
                "isLactoseFreeFriendly": False,
            },
            {
                "category": "Executive Lunch",
                "isVeganFriendly": False,
                "isGlutenFreeFriendly": True,
                "isLactoseFreeFriendly": False,
            },
            {
                "category": "Fast Food",
                "isVeganFriendly": False,
                "isGlutenFreeFriendly": False,
                "isLactoseFreeFriendly": True,
            },
            {
                "category": "Cafe",
                "isVeganFriendly": False,
                "isGlutenFreeFriendly": False,
                "isLactoseFreeFriendly": False,
            },
        ]

    def find_option(self, result, kind, option):
        return next(
            row for row in result["rows"]
            if row["type"] == kind and row["option"] == option
        )

    def test_unique_searches(self):
        events = [
            filter_event("1", "category", "Fast Food"),
            filter_event("1", "dietary", "vegan"),
        ]

        result = bq12_catalina(events, self.restaurants)

        self.assertEqual(result["searches"], 1)

    def test_duplicate_events(self):
        event = filter_event("1", "dietary", "vegan")

        result = bq12_catalina(
            [event, event, event],
            self.restaurants,
        )

        vegan = self.find_option(result, "dietary", "vegan")

        self.assertEqual(result["searches"], 1)
        self.assertEqual(vegan["requests"], 1)

    def test_demand_percentage(self):
        events = [
            filter_event("1", "dietary", "vegan"),
            filter_event("2", "dietary", "vegan"),
            filter_event("3", "category", "Cafe"),
            filter_event("4", "none", "none"),
        ]

        result = bq12_catalina(events, self.restaurants)

        vegan = self.find_option(result, "dietary", "vegan")

        self.assertEqual(result["searches"], 4)
        self.assertEqual(vegan["demand_pct"], 50.0)

    def test_supply_percentage(self):
        result = bq12_catalina([], self.restaurants)

        vegan = self.find_option(result, "dietary", "vegan")
        fast_food = self.find_option(result, "category", "Fast Food")

        self.assertEqual(vegan["supply_pct"], 25.0)
        self.assertEqual(fast_food["supply_pct"], 50.0)

    def test_demand_supply_gap(self):
        events = [
            filter_event("1", "dietary", "vegan"),
            filter_event("2", "dietary", "vegan"),
            filter_event("3", "none", "none"),
            filter_event("4", "none", "none"),
        ]

        result = bq12_catalina(events, self.restaurants)

        vegan = self.find_option(result, "dietary", "vegan")

        self.assertEqual(vegan["gap"], 25.0)
        self.assertEqual(result["top_gap"]["option"], "vegan")

    def test_multiple_preferences(self):
        events = [
            filter_event("1", "dietary", "vegan"),
            filter_event("1", "dietary", "gluten_free"),
        ]

        result = bq12_catalina(events, self.restaurants)

        vegan = self.find_option(result, "dietary", "vegan")
        gluten_free = self.find_option(
            result, "dietary", "gluten_free"
        )

        self.assertEqual(result["searches"], 1)
        self.assertEqual(vegan["requests"], 1)
        self.assertEqual(gluten_free["requests"], 1)

    def test_missing_apply_id(self):
        event = filter_event(None, "dietary", "vegan")

        result = bq12_catalina([event], self.restaurants)

        self.assertEqual(result["searches"], 0)
        self.assertEqual(result["skipped_events"], 1)

    def test_kotlin_events_are_excluded(self):
        events = [
            filter_event("1", "dietary", "vegan"),
            filter_event(
                "2", "dietary", "vegan", "Android-Kotlin"
            ),
        ]

        result = bq12_catalina(events, self.restaurants)

        self.assertEqual(result["searches"], 1)

    def test_empty_searches(self):
        result = bq12_catalina([], self.restaurants)

        self.assertEqual(result["searches"], 0)
        self.assertIsNone(result["top_gap"])

    def test_empty_restaurants(self):
        events = [
            filter_event("1", "dietary", "vegan"),
        ]

        result = bq12_catalina(events, [])

        vegan = self.find_option(result, "dietary", "vegan")

        self.assertEqual(result["restaurants"], 0)
        self.assertIsNone(vegan["supply_pct"])
        self.assertIsNone(vegan["gap"])
        self.assertIsNone(result["top_gap"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
