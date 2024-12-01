#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif


/*
Adaptation de Neon LOVE Fix de gelami: https://www.shadertoy.com/view/7l3GDS
Par Jeanclaude Stephane
*/

uniform int pointerCount;
uniform vec3 pointers[10];
uniform vec2 resolution;
uniform int frame;
uniform float battery;
uniform float ftime;
uniform sampler2D backbuffer;
uniform int powerConnected;
uniform float mediaVolume;

#define iResolution vec3(resolution,0.)

/* LIGHTNING*/
#define iTime float(frame)
const float scale = 15.;
const float acc = 16384.;
const int OCTAVES = 8;
const float LENGTH = .03;

/* HEART */
const int POINT_COUNT = 8;
vec2 points[POINT_COUNT];
const float speed = 0.3;
const float len = .5;
const float scaleHeart = 0.012;
float intensity = 1.3;
float radius = 0.015; //0.015;

float thickness = .0025;

//https://www.shadertoy.com/view/MlKcDD
//Signed distance to a quadratic bezier
float sdBezier(vec2 pos, vec2 A, vec2 B, vec2 C){
    vec2 a = B - A;
    vec2 b = A - 2.0*B + C;
    vec2 c = a * 2.0;
    vec2 d = A - pos;

    float kk = 1.0 / dot(b,b);
    float kx = kk * dot(a,b);
    float ky = kk * (2.0*dot(a,a)+dot(d,b)) / 3.0;
    float kz = kk * dot(d,a);

    float res = 0.0;

    float p = ky - kx*kx;
    float p3 = p*p*p;
    float q = kx*(2.0*kx*kx - 3.0*ky) + kz;
    float h = q*q + 4.0*p3;

    if(h >= 0.0){
        h = sqrt(h);
        vec2 x = (vec2(h, -h) - q) / 2.0;
        vec2 uv = sign(x)*pow(abs(x), vec2(1.0/3.0));
        float t = uv.x + uv.y - kx;
        t = clamp( t, 0.0, 1.0 );

        // 1 root
        vec2 qos = d + (c + b*t)*t;
        res = length(qos);
    }else{
        float z = sqrt(-p);
        float v = acos( q/(p*z*2.0) ) / 3.0;
        float m = cos(v);
        float n = sin(v)*1.732050808;
        vec3 t = vec3(m + m, -n - m, n - m) * z - kx;
        t = clamp( t, 0.0, 1.0 );

        // 3 roots
        vec2 qos = d + (c + b*t.x)*t.x;
        float dis = dot(qos,qos);

        res = dis;

        qos = d + (c + b*t.y)*t.y;
        dis = dot(qos,qos);
        res = min(res,dis);

        qos = d + (c + b*t.z)*t.z;
        dis = dot(qos,qos);
        res = min(res,dis);

        res = sqrt( res );
    }

    return res;
}


//http://mathworld.wolfram.com/HeartCurve.html
vec2 getHeartPosition(float t){
    return vec2(16.0 * sin(t) * sin(t) * sin(t),
                -(13.0 * cos(t) - 5.0 * cos(2.0*t)
                - 2.0 * cos(3.0*t) - cos(4.0*t)));
}

//https://www.shadertoy.com/view/3s3GDn
float getGlow(float dist, float radius, float intensity){
    return pow(radius*dist, intensity);
}

// Changes in here

float getSegment(float t, vec2 pos, float offset){
	for(int i = 0; i < POINT_COUNT; i++){
        points[i] = getHeartPosition(offset + float(i)* len * battery + fract(speed * t) * 6.28);
    }

    vec2 c = (points[0] + points[1]) / 2.0;
    vec2 c_prev;
		float light = 0.;
    const float eps = 1e-10;

    for(int i = 0; i < POINT_COUNT-1; i++){
        //https://tinyurl.com/y2htbwkm
        c_prev = c;
        c = (points[i] + points[i+1]) / 2.0;
        float d = sdBezier(pos, scaleHeart * c_prev, scaleHeart * points[i], scaleHeart * c);
        float e = i > 0 ? distance(pos, scaleHeart * c_prev) : 1000.;
        light += 1. / max(d - thickness, eps);
        light -= 1. / max(e - thickness, eps);
    }

    return max(0.0, light);
}

/* ** LIGHTNING ** */
	float rand(float seed)
{
  return fract(sin(seed) * 522734.567);
}

float fractalWave(float pct, float dist)
{
    float f = 0.;
    float amp = dist * 1.5; // atténué
    float freq = dist; // doit dependre de la distance
    for(int i = 0; i < 5; i++){
        f += amp * sin(freq * pct);
        amp *= .5;
        freq *= 2.2;
    }
    return f;
}

vec2 proj(vec2 p, vec2 a, vec2 b){

    vec2 pa = p - a;
    vec2 ba = b - a;

    vec2 t = dot(pa,ba)/dot(ba,ba) * ba + a;
    return t;
}

float projPCT(vec2 p, vec2 a, vec2 b){

    vec2 pa = p - a;
    vec2 ba = b - a;

    float t = dot(pa,ba)/dot(ba,ba);
    return t;
}

float lightningMask(vec2 uv, vec2 m, vec2 center){
			float randValue = rand(iTime);
			if(randValue> .5){
	    for (int n = 0; n < pointerCount; ++n) {
    			vec2 pos = pointers[0].xy / resolution.xy;
        	center = pos;
    }
    }
    vec2 p = proj(uv,center, m);
    float pct = projPCT(uv,center,m) * scale + randValue * 1000.;
    float mask = sin(clamp(projPCT(uv,center, m),0.,1.) * 3.141592);
    float dist2 = distance(m, center);//distance entre m et center, entre 0.0 et 1.0
    float wave = fractalWave(pct, dist2);
    float dotting = rand(floor(pct* 10.));
    float dist = distance(uv,p) * scale;

    if(m.x > center.x ){
        if(uv.y > p.y){
            dist *= -1.;
        }
    }else{
        if(abs(m.x - center.x) < .001){
            if(uv.x < m.x){
                if(m.y > center.y){
                    dist *= -1.;
                }

            }else{
                if(m.y < center.y){
                    dist *= -1.;
                }
            }
        }
        else if(uv.y < p.y){
            dist *= -1.;
        }
    }
    wave *= mask;
    float waveOff = (wave + .1);
    float f = 0.;

    f = abs(wave - dist);
    f = 1. - smoothstep(0.,LENGTH, f);
    f = f * smoothstep(.0,.2,mask);
    float rand = mod(float(frame), 10.0) / 10.0;
    rand *= 2.;
    rand += 1.9;
    f *= 1. - (rand *uv.y);
    return f;
}

vec3 Lightning(vec2 uvLight, vec2 m, vec2 endPoint){
	 /* **LIGHTNING** */
    vec4 tex = vec4(0.);
    vec2 prev = vec2(tex.z / acc, tex.w / acc);
    vec2 newCenter = prev + .02 * (m - prev);
    vec2 write = vec2(newCenter.x * acc, newCenter.y * acc);
    tex.w = write.x;
    float f = lightningMask(uvLight, m, endPoint);
    tex.xyz += vec3(clamp(f,0.,100.));
    tex.xyz *= 10.; // intensity
    tex.xyz *= vec3(.30,.3,.97); //color

	  return tex.xyz;
	}


vec3 Circle(vec2 pos, vec2 uv, float radius) {
    float mx = max(resolution.x, resolution.y);
    //vec3 color= vec3(sqrt(distance((uv, pos.xy/mx)*(1./radius))));
    //vec3 color = vec3(sqrt(distance(uv, pos.xy / mx) / radius));

    vec3 color = max(vec3(.0), smoothstep(
        0.15,
        0.01,
        distance(uv, pos.xy / mx)*(1./radius)));

    return color;
}


void main(){
		float mx = max(resolution.x, resolution.y);
		vec2 uv = gl_FragCoord.xy / resolution.xy;
		vec2 uvR = gl_FragCoord.xy / resolution.xy;
		vec2 uvG = gl_FragCoord.xy / resolution.xy;
		vec2 uvB = gl_FragCoord.xy / resolution.xy;
		vec2 uv2 = gl_FragCoord.xy / mx;

		vec3 test = vec3(0.);
		 for (int n = 0; n < pointerCount; ++n) {
          uvR -= Circle(pointers[n].xy, uv2, .8).xy * .004;
          uvG *= Circle(pointers[n].xy, uv2, .8).xy * .005;
          uvG /= Circle(pointers[n].xy, uv2, .8).xy * .005;
          uvB += Circle(pointers[n].xy, uv2, .8).xy * .006;
    }
    vec2 fpos = vec2(resolution.x*.5, resolution.y*.5);
    			float freq = 2209.;
    			float amp = 100.;
    			float size = .5;

    			if(powerConnected ==1){
    				freq=3.;
    				}

    			fpos += vec2(sin(ftime*freq),cos(ftime*freq))*amp;
    			uvR -= Circle(fpos, uv2, size).xy * .004;
          uvG *= Circle(fpos, uv2, size).xy * .005;
          uvG /= Circle(fpos, uv2, size).xy * .005;
          uvB += Circle(fpos, uv2, size).xy * .006;


		float batteryIndice = clamp((float(powerConnected)+battery), .0, 1.);

			/* **HEART** */
    float widthHeightRatio = resolution.x/resolution.y;
    vec2 centre = vec2(0.5, 0.5);
    float zoom = 1.5 - battery;
    vec2 pos = (centre - uv) * zoom;
    pos.y /= widthHeightRatio;
    //Shift upwards to centre heart
    pos.y += 0.03;

    //float t = float(frame)*.01;
    float iTime2 = asin(ftime) / 3.14159 + 100.9;
    float t = iTime2;

    //Get first segment
    float dist = getSegment(t, pos, 0.0);
    float glowIntensity = 1.;
    glowIntensity += 3. * float(powerConnected);
    float glow = batteryIndice * glowIntensity * getGlow(dist, radius, intensity);

    vec3 col = vec3(0.0);
    col += glow * vec3(1.0,0.05,0.3);
    dist = getSegment(t, pos, 3.4);
    glow = batteryIndice * glowIntensity * getGlow(dist, radius, intensity);
    col += glow * vec3(0.1,0.4,1.0);


    // Tone mapping
		col = (1.0 - exp(-col))abs(sin(ftime.3)+1.5);

    //Gamma
    float gamma = 1.5;
		col = pow(col, vec3(1.0 / gamma));
    col *= (1.5 * abs(sin(ftime * (5. *(1.- batteryIndice))))+.5) * batteryIndice;

		/LIGHTNING/
    float endP = (-.07 * battery + .4556)+ .5;
		vec2 endPos = vec2(.5, endP);
    vec3 IsCharging = float(powerConnected) * Lightning(uv, vec2(.5, .0), endPos);
    IsCharging = mix(IsCharging, IsCharging * vec3(1.0,0.05,0.3)*3., 3.*uv.y);
    col += IsCharging;


  // Appliquer un facteur de fondu pour l'image précédente
    float fadeFactor = 0.9; // Ajuste ce facteur pour contrôler l'intensité du fondu
		float backR = texture2D(backbuffer, uvR).r;
		float backG = texture2D(backbuffer, uvG).g;
		float backB = texture2D(backbuffer, uvB).b;

		vec3 back = vec3(backR, backG, backB);

    // Ajouter la couleur actuelle avec la couleur de l'image précédente

    col = mix(col, back, fadeFactor);

    col = mix(col, vec3(1.0, 0., 0.), mediaVolume);

		col = clamp(col, 0.0, 1.0);

    //Output to screen
   gl_FragColor = vec4(col,1.0);

}