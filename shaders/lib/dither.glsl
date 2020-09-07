#define MAG3 vec3(443.8975,397.2973, 491.1871)
#define MAG5 vec3(0.11764705882352941, 0.4117647058823529, 1.3529411764705883)

float dither17() {
  return fract(
    dot(
      vec3(gl_FragCoord.xy, 0.0),
      MAG5
      )
    );
}

float hash12()
{
	vec3 p3 = fract(vec3(gl_FragCoord.xyx) * MAG3);
  p3 += dot(p3, p3.yzx + 19.19);
  return fract((p3.x + p3.y) * p3.z);
}

float ditherGradNoise() {
  return fract(
    52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y)
    );
}

float bayer2(vec2 a){
	a = floor(a);
	return fract(dot(a, vec2(.5, a.y * .75)));
}

#define bayer4(a) (bayer2(.5 * (a)) * .25 + bayer2(a))
#define bayer8(a) (bayer4(.5 * (a)) * .25 + bayer2(a))
#define bayer16(a) (bayer8(.5 * (a)) * .25 + bayer2(a))
#define bayer32(a) (bayer16(.5 * (a)) * .25 + bayer2(a))
#define bayer64(a) (bayer32(.5 * (a)) * .25 + bayer2(a))
#define bayer128(a) (bayer64(.5 * (a)) * .25 + bayer2(a))
#define bayer256(a) (bayer128(.5 * (a)) * .2