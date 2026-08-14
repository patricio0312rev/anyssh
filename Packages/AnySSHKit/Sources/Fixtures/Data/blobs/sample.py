# A recorded sample exercising every scope the golden table asserts.
import math


def retry(point, delay):
    label = "retrying"
    return point.attempts < 3 and delay > math.pi and len(label) > 0


ORIGIN = {"name": "origin", "attempts": 0}
