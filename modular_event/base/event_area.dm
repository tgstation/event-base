/area/event
	name = "Event Area"
	requires_power = FALSE
	default_gravity = STANDARD_GRAVITY

	// Fullbright
	static_lighting = FALSE
	base_lighting_alpha = 255

// Make arrivals area fullbright, since this is where latejoins go
/area/shuttle/arrival
	requires_power = FALSE
	default_gravity = STANDARD_GRAVITY

	// Fullbright
	static_lighting = FALSE
	base_lighting_alpha = 255
