// credits to 'Danilo Guanabara' => https://www.shadertoy.com/view/XsXXDn
precision mediump float;


uniform vec2 resolution;
uniform int frame;
uniform vec2 touch;

#define t float(frame)/100.
#define r resolution.xy

void main(void) {

	vec3 c;
	float l,z=t;

	for(int i=0;i<3;i++) {
		vec2 uv,p=gl_FragCoord.xy/r;
		uv=p+touch*0.001*p;
		p-=.5;
		p.x*=r.x/r.y;
		z+=.07;
		l=length(p);
		uv+=p/l*(sin(z)+1.)*abs(sin(l*9.-z-z));
		c[i]=.01/length(mod(uv,1.)-.5);
	}

	gl_FragColor=vec4(c/l,t);
}