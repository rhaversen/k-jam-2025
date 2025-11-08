shader_type spatial;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;

void vertex() {
    // Example: a small wavy offset
    // VERTEX.y += sin(VERTEX.x * 1.0 + VERTEX.z + 3.0 * TIME) * 0.1 + cos(VERTEX.x + VERTEX.z * 3.0 + 2.0 * TIME) * 0.1;	
    // POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
}

void fragment() {
    //float a = sin(VERTEX.x * 1.0 + 5.0 * TIME) * 0.1 + cos(2.0 * VERTEX.z + 3.0 * TIME) * 0.1;
	//ALBEDO = vec3(a,a,a);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
