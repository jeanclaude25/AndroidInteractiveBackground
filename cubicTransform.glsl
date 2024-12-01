//Forked from // sorry, I have to search for it
//Adapted to Shader Editor by Jeanclaude Stephane

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

uniform vec2 resolution;
uniform float time;
uniform vec4 date;


#define iTime time

#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

float t; //time
vec3 glw = vec3(0); //glow

float bx(vec3 p, vec3 s) //box sdf
{
  vec3 q=abs(p)-s*1.;
  return min(max(q.x,max(q.x,q.z)), 0.) + length(max(q,0.));
}



vec2 mp(vec3 p) //map/scene
{
  vec3 pp = p; //temp position


  float fb = atan(t)*0.75+0.5;
  float tt = t + fb*0.2;
  float g = length(pp) - fb*2.;
  glw +=0.421/(0.01+g*g)*vec3(00.2,0.5,0.9);
   pp.yz*=rot(iTime);
        pp.xz*=rot(iTime);
  for(float i=0.;i<5.;i++)
  {
     pp.xy=abs(pp.xy)-1.2 - fb*0.5;
     pp.yz*=rot(iTime);
        pp.xz*=rot(iTime);


  }
  vec2 b = vec2(bx(pp, vec3(1.)) - 0.1, 1.); //create centre crystal
  pp=p; //reset temp position



  vec2 c = vec2((pp,1.),2.); //outer cylinders


  glw += 0.201/(0.01+g*g)*mix(vec3(0.1,0.0,0.9), vec3(0.9,0.0,0.1), (pp.y+10.)/20.); //add glow with y based colour


  return b.x < c.x ? b : c;
}


vec2 tr(vec3 ro,vec3 rd,float x) //raymarcher
{
  vec2 d = vec2(0);
  for(int i = 0; i < 256; i++)
  {
    vec3 p=ro+rd*d.x;
    vec2 s=mp(p);s.x*=x;
    d.x+=s.x;d.y=s.y;
    if(d.x>64.||s.x<0.001)break;
  }
  if(d.x>64.)d.y=0.;return d;
}

vec3 nm(vec3 p) //normal calc
{
  vec2 e = vec2(0.001,0); return normalize(mp(p).x-vec3(mp(p-e.xyy).x,mp(p-e.yxy).x,mp(p-e.yyx).x));
}

vec4 px(vec4 h, vec3 rd, vec3 n) //hit "shader" - calculates the colour from position + object + ray + normal data
{
  vec4 b=vec4(0,0,0,1); //background
  if(h.a==0.)return vec4(b.rgb,1.); //return background for object id 0
  vec4 a=h.a == 1. ? vec4(cos(t)*0.5+0.5,0.1,0.3, 0.2) : vec4(0.,0.,0.,0.8); //base colour
  float d=dot(n,-rd); //unclamped diffuse
  float dd=max(d,0.); //diffuse proper
  float f=pow(1.-d,4.); //easy fres by using inverse of unclamped diffuse
  float s=pow(abs(dot(reflect(rd,n),-rd)),40.); //specular
  return vec4(a.rgb*(dd+f)+s,a.a); //mix together
}

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
  t=iTime; //assign time global
  vec2 uv = vec2(fragCoord.x/resolution.x, fragCoord.y/resolution.y); //uv
  uv-=0.5;uv/=vec2(resolution.y/resolution.x,1); //uv normalise
  vec3 ro = vec3(0, 0, -30),rd=normalize(vec3(uv + vec2(0, 0),1.)), //ray origin and direction
  oro=ro,ord=rd,cn,cp,cc;float ts=1.; //lots of variables to track transparency loop
  for(int i=0;i<10;i++) //transparency loop
  {
    vec2 f=tr(oro,ord,1.); //march to front object
    cp=oro+ord*f.x;cn=nm(cp); //update current position and normal
    vec4 c=px(vec4(cp,f.y),ord,cn); //colour for front object
    if(f.y==0.||c.a==1.){cc=mix(cc,c.rgb,ts);break;}; //mix colour and break if object is solid or there was no object
    ro=cp-cn*0.01;rd=refract(ord,cn,1./1.3); //refract and update ray
    vec2 z=tr(ro,rd,-1.); //march through object
    cp=ro+rd*z.x;cn=nm(cp); //update current position and normal
    oro=cp+cn*0.01;ord=refract(rd,-cn,1.3); //refract and update the original ray variables
    if(dot(ord,ord)==0.)ord=reflect(rd,-cn); //reflect if refraction failed
    cc=mix(cc,c.rgb,ts);ts-=c.a; //mix colour
    if(ts<=0.)break; //break if we reached 0 transmission
  }
  fragColor=vec4(cc + glw,1); //write output
}

void main() {
	vec4 fragment_color;
	mainImage(fragment_color, gl_FragCoord.xy);
	gl_FragColor = fragment_color;
}