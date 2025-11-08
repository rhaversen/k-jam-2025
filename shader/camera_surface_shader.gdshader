shader_type spatial;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_linear_mipmap;
uniform sampler2D DEPTH_TEXTURE : source_color, hint_depth_texture;

uniform bool edge_only = true;

uniform float edge_threshold = 0.2;
uniform vec3 line_color: source_color = vec3(0.043, 0.282, 0.467);
uniform vec3 background_color: source_color = vec3(0.408, 0.969, 0.694);

uniform float depth_range:hint_range(0.1, 100.0, 0.1);

uniform bool stress_level_1 = false; // variable that can be changed from code

uniform float blind:hint_range(0.0, 1.0) = 0.0; // variable that can be changed from code

const mat3 sobel_y = mat3(
	vec3(1.0, 0.0, -1.0),
	vec3(2.0, 0.0, -2.0),
	vec3(1.0, 0.0, -1.0)
);

const mat3 sobel_x = mat3(
	vec3(1.0, 2.0, 1.0),
	vec3(0.0, 0.0, 0.0),
	vec3(-1.0, -2.0, -1.0)
);

void vertex(){
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 screen_color = texture(SCREEN_TEXTURE, uv);
	vec3 normal = texture(NORMAL_TEXTURE, uv).rgb;
	normal = normal * 2.0 - 1.0;
	vec2 offset = 1.0 / VIEWPORT_SIZE;

	float depth = FRAGCOORD.z; // texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z / depth_range;
	
	ALBEDO = normal; 				// showing normal texture
    
	if (stress_level_1) {
		ALPHA = 0.1;
	} else {
		ALPHA = 0.0;
	}
	
	//if ((uv.x-0.75)*(uv.x-0.75) + 0.1*(uv.y-0.5)*(uv.y-0.5) >= 0.3 * 0.3) {
	if (blind > 0.0) {
		float d = (uv.x-0.75)*(uv.x-0.75)+ 0.1*(uv.y-0.5)*(uv.y-0.5);
		float new_alpha = (blind*blind)*d/(0.35*0.35+0.1*0.35*0.35);
		ALBEDO = mix(vec3(0.0,0.0,0.0), ALBEDO, 1.0-new_alpha);
		ALPHA = new_alpha;
	}

    // float r = sin(TIME) * 0.5 + 0.5;   // oscillates between 0–1
    // float g = sin(TIME + 2.0) * 0.5 + 0.5; // phase-shifted
    // float b = sin(TIME + 4.0) * 0.5 + 0.5; // phase-shifted
	// ALBEDO = vec3(1.0,.0,.0);
	
	// float a = sin(TIME) * 0.1 + 0.1;   // oscillates between 0–1
	// ALPHA = a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
