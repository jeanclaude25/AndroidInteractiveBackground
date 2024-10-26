#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;
uniform sampler2D backbuffer;
uniform float startRandom;

vec3 Circle(vec2 pos, vec2 uv, float radius) {
    float mx = max(resolution.x, resolution.y);
    vec3 color = max(vec3(.0), smoothstep(
        0.085,
        0.08,
        distance(uv, pos.xy / mx)*(1./radius)));
       float rVal = startRandom * 3.0;
		color *= vec3(mod(rVal,1.0), mod(rVal,2.0), mod(rVal,3.0));
    return color;
}

vec3 Stroke(vec2 pos, vec2 uv, float radius, float thickness){
	vec3 color = Circle(pos, uv, radius);
	color -= Circle(pos, uv, radius - thickness);
	color *= 55.;
	return color;
	}

vec3 Line(vec2 pos1, vec2 pos2, vec2 uv) {
    float mx = max(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    pos1 /= mx;
    pos2 /= mx;
    vec2 dir = pos2 - pos1;
    float len = length(dir);
    vec2 dirNorm = dir / len;
    float proj = clamp(dot(uv - pos1, dirNorm), 0.0, len);
    vec2 projPos = pos1 + dirNorm * proj;
    float dist = length(uv - projPos);
    float lineWidth = 0.001;  // Largeur de la ligne ajustée
    color += vec3(1.0) * smoothstep(lineWidth, lineWidth * 0.8, dist);

    return color;
}

void main(void) {
    float mx = max(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / mx;
    vec2 uv2 = gl_FragCoord.xy / resolution.xy;
    vec3 color = vec3(0.0);

    for (int n = 0; n < pointerCount; ++n) {
        color += Circle(pointers[n].xy, uv, .8);
        color += Stroke(pointers[n].xy, uv, 1., .01);
        color += Stroke(pointers[n].xy, uv, 1.2, .001);
        if (n > 0) {
            color += Line(pointers[n-1].xy, pointers[n].xy, uv);
        }
        if(n>1){
        	color += Line(pointers[0].xy, pointers[n].xy, uv);
        	}
    }

    // Appliquer un facteur de fondu pour l'image précédente
    float fadeFactor = 0.8; // Ajuste ce facteur pour contrôler l'intensité du fondu
		vec3 back = texture2D(backbuffer, uv2).rgb;
    // Ajouter la couleur actuelle avec la couleur de l'image précédente
    color = mix(color, back, fadeFactor);
    color -= .005;
    color *=1.1;
    gl_FragColor = vec4(color, 1.0);
}