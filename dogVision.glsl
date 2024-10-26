#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform vec2 cameraAddent;
uniform mat2 cameraOrientation;
uniform samplerExternalOES cameraBack;


uniform int pointerCount;
uniform vec3 pointers[5];
uniform sampler2D noise;
uniform int frame;

const float FLICKER_SPEED = 50.;
const float LEVELS = 40.;
const float BLUR_INTENSITY = 0.02;
const float BLUR_BASE = 32.;
const float MOTION = 6.9;

float Mask(float pos1, vec2 uv) {
    float color = 0.0;
    pos1 /= resolution.x;
    if(pos1<uv.x) {
    	color=1.0;
    	}
    return color;
}

vec3 dogProcess(vec3 source){
	float r = source.r;
	float g = source.g;
	float b = source.b;

	float nG = .5 * ( r + g );
	float nR = nG;
	float nB = b;

	return vec3(nG, nR, nB);
	}

vec2 blurUV(vec2 uv, int step){
		vec2 blurredUV = uv;
		for(int n = 0; n < step; ++n){
			vec2 blurredUV1 = texture2D(noise, uv * BLUR_BASE * float(step)).rg * (BLUR_INTENSITY/float(step));
			vec2 blurredUV2 = texture2D(noise, uv * BLUR_BASE * float(step)+0.005).rg * (BLUR_INTENSITY/float(step));
			blurredUV += mix(blurredUV1, blurredUV2, mod(float(frame)/60.,1.));
		}
	return blurredUV;
	}


vec3 quantizeColor(vec3 color){
		color.r = floor(color.r * LEVELS) / LEVELS;
		color.g = floor(color.g * LEVELS) / LEVELS;
		color.b = floor(color.b * LEVELS) / LEVELS;
		return color;
	}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 st = cameraAddent + uv * cameraOrientation;

    vec3 camera = texture2D(cameraBack, st).rgb;
camera *= vec3(0.95);

		vec2 blurredUV = st;
		float dist = length(uv - vec2(0.5, 0.5));
		float depthBlur = smoothstep(0.2, 0.5, dist);
		blurredUV = mix(blurredUV, blurUV(st, 2 + int(depthBlur * 10.0)), depthBlur);
		float peripheralSharpness = smoothstep(0.2, 0.8, dist);
		blurredUV = mix(blurredUV, st, peripheralSharpness*0.03);
		blurredUV = mix(st, blurredUV, camera.r);
		vec3 dogCamera = texture2D(cameraBack, blurredUV).rgb;

		float flicker = 0.98 + 0.02 * sin(float(frame) * FLICKER_SPEED * camera.r);
		vec3 dogView = dogProcess(dogCamera) * flicker;

		float contrastFactor = 1.0 + 0.5 * smoothstep(.3, .8, dist) * camera.r;
		dogView = mix(vec3(0.5), dogView, contrastFactor);
		dogView = quantizeColor(dogView);

		float lightFactor = (1.- camera.r) - 0.2;
		dogView += dogView * lightFactor;
		vec3 enhancedLowLight = mix(dogView, dogView * 1.2, smoothstep(0.0, 0.3, length(dogView)));

		vec3 color = vec3(0.0);
		float mask = 0.0;

    for (int n = 0; n < pointerCount; ++n) {
			mask = Mask(pointers[n].x, uv);
    }

		color += mask * camera;
		color += (1.-mask) * enhancedLowLight;


    gl_FragColor = vec4(color, 1.0);
}