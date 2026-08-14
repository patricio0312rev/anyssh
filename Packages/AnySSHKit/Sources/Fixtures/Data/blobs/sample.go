// A recorded sample exercising every scope the golden table asserts.
package waypoint

import "errors"

type Waypoint struct {
	Name     string
	Attempts int
}

func Retry(point Waypoint, delay float64) (bool, error) {
	if point.Attempts > 3 {
		return false, errors.New("exhausted")
	}
	return delay > 0.5, nil
}
