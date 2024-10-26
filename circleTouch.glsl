#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec3 pointers[10];
uniform int pointerCount;

vec3 Circle(vec2 pos, vec2 uv, float radius){
	float mx = max(resolution.x, resolution.y);

	vec3 color = max(vec3(0.), smoothstep(
		0.085,
		0.08,
		distance(uv, pos.xy/mx) * (1./radius)));
	return color;
	}

void main(void) {
    float mx = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / mx;

   vec3 color = vec3(0.);
   for(int n = 0; n<pointerCount; ++n){
   	color += Circle(pointers[n].xy, uv, 0.8);
   	}


    gl_FragColor = vec4(color, 1.0);
}