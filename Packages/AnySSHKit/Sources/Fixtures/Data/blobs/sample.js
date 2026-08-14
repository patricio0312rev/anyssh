// A recorded sample exercising every scope the golden table asserts.
const defaults = { attempts: 0, label: "origin" };

function retry(point, delay) {
    return point.attempts < 3 && delay > 0.5;
}

export { defaults, retry };
