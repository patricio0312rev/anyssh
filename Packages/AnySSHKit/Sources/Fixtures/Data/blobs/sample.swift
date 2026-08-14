import Foundation

/// A recorded sample exercising every scope the golden table asserts.
struct Waypoint {
    let name: String
    let attempts: Int

    func retry(after delay: Double) -> Bool {
        // A line comment the golden table reads.
        return attempts < 3 && delay > 0.5
    }
}

let origin = Waypoint(name: "origin", attempts: 0)
