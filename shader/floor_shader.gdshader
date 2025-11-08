shader_type spatial;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

uniform bool stress_level_1 = false; // variable that can be changed from code

void vertex() {
     // Example: a small wavy offset
	if (stress_level_1) {
	    float t = TIME*2.0;
	    vec3 pos = VERTEX;
		
		float amplitude = 0.04;
		float frequency = 0.02;
		float steepness = 0.0;

	    // combine 3 different sine directions
	    pos.y += sin(pos.x * frequency + t * 1.0) * amplitude;
	    pos.y += sin(pos.z * (frequency * 0.8) + t * 0.7) * amplitude * 0.8;
	    pos.y += sin((pos.x + pos.z) * (frequency * 0.6) + t * 0.5) * amplitude * 0.6;

	    // optional slight horizontal distortion for wave tilt
	    pos.x += sin(pos.z * frequency + t) * steepness * amplitude;
	    pos.z += cos(pos.x * frequency + t * 0.9) * steepness * amplitude;
		
		pos.y += 1.1;

	    VERTEX = pos;
	} else {
	    vec3 pos = VERTEX;
		pos.y += 1.1;
	    VERTEX = pos;
	}
}

void fragment() {
    float a = 1.0; // sin(VERTEX.x * 1.0 + 5.0 * TIME) * 0.1 + cos(2.0 * VERTEX.z + 3.0 * TIME) * 0.1;
	ALBEDO = vec3(a,a,a);
	// ALPHA = 0.1;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
