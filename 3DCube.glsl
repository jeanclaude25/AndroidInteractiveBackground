//Forked from https://www.shadertoy.com/view/l3fyWl by Kon
//Adapted to Shader Editor by Jeanclaude Stephane
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform mat3 rotationMatrix;
uniform vec3 rotationVector;
uniform vec3 magnetic;
uniform int frame;

const float PI = 3.1415926535897932;

#define iTime time

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

float degToRadian(float deg){ return deg * (PI/180.0); }

vec3 rotateX(vec3 p, float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return vec3(
        p.x,
        c * p.y - s * p.z,
        s * p.y + c * p.z
    );
}

vec3 rotateY(vec3 p, float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return vec3(
        c * p.x + s * p.z,
        p.y,
        -s * p.x + c * p.z
    );
}

vec3 rotateZ(vec3 p, float angle)
{
    float s = sin(angle);
    float c = cos(angle);
    return vec3(
        c * p.x - s * p.y,
        s * p.x + c * p.y,
        p.z
    );
}

float udBoxFrame(vec3 p,vec3 b,float e)
{
    vec3 a = abs(p)
       , m = 1. - step(a, a.yzx) * step(a, a.zxy);
    return length(max(abs(a - b) - e, 0.) * m);
}

mat3 correctionMatrix = mat3(
    1.0,  0.0,  0.0,  // X' = X
    0.0,  0.0, -1.0,  // Y' = -Z
    0.0,  1.0,  0.0   // Z' = Y
);

uniform float previousAngle;

float map(vec3 p)
{
		vec2 niv = vec2(0.);
    niv.x = -rotationVector.x - .3;
    niv.x *= PI/2.;
    p = rotateX(p, niv.x);


		float val1 = smoothstep(0.05 * magnetic.x,0.,1.);
		float val2 = degToRadian(rotationVector.z*180.);

     p = rotateZ(p, val2);


    // Cube parameters
    vec3 b = vec3(1.0); // Half-size of the cube
    float e = 0.02;     // Edge thickness
    return udBoxFrame(p, b, e);
}

vec3 calcNormal(vec3 p)
{
    float eps = 0.001;
    vec2 e = vec2(1.0, -1.0) * eps;
    return normalize(
        e.xyy * map(p + e.xyy) +
        e.yyx * map(p + e.yyx) +
        e.yxy * map(p + e.yxy) +
        e.xxx * map(p + e.xxx)
    );
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalize pixel coordinates (from -1 to 1)
    vec2 uv = (fragCoord.xy / resolution.xy) * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;

    // Camera setup
    vec3 camPos = vec3(0.0, 0., -5);
    vec3 camTarget = vec3(0.0, 0.0, 0.0);
    vec3 camUp = vec3(0.0, 2.0, 0.0);

    // Camera coordinate system
    vec3 camForward = normalize(camTarget - camPos);
    vec3 camRight = normalize(cross(camForward, camUp));
    vec3 camUpActual = cross(camRight, camForward);

    // Ray direction
    vec3 rayDir = normalize(camForward + uv.x * camRight + uv.y * camUpActual);

    // Ray marching parameters
    float t = 0.0;
    float maxDistance = 20.0;
    int maxSteps = 100;
    float minDistance = 0.001;
    float d = 0.0;
    vec3 p;
    int i;
    for (i = 0; i < maxSteps; i++)
    {
        p = camPos + t * rayDir;
        d = map(p);
        if (d < minDistance)
            break;
        t += d;
        if (t >= maxDistance)
            break;
    }
    if (t >= maxDistance)
    {
        fragColor = vec4(0.0);
    }
    else
    {
        // Compute normal
        vec3 normal = calcNormal(p);

        // Simple shading
        vec3 lightDir = normalize(vec3(0.5, 1.0, -0.5));
        float diff = clamp(dot(normal, lightDir), 0.0, 1.0);

        fragColor = vec4(vec3(diff), 1.0);
    }
}

void main() {
	vec4 fragment_color;
	mainImage(fragment_color, gl_FragCoord.xy);
	gl_FragColor = fragment_color;
}