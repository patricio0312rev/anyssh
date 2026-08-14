// A recorded sample exercising every scope the golden table asserts.
export interface Waypoint {
    name: string;
    attempts: number;
}

export function retry(point: Waypoint, delay: number): boolean {
    const label = "retrying";
    return point.attempts < 3 && delay > 0.5 && label.length > 0;
}

export const origin: Waypoint = { name: "origin", attempts: 0 };
