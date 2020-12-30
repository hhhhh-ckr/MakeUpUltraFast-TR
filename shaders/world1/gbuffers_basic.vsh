#version 120
/* MakeUp Ultra Fast - gbuffers_clouds.vsh
Render: Basic elements

Javier Garduño - GNU Lesser General Public License v3.0
*/

#define THE_END
#define NO_SHADOWS

#include "/lib/config.glsl"
#include "/lib/color_utils_end.glsl"

// Varyings (per thread shared variables)
varying vec4 tint_color;
varying float fog_density_coeff;
varying float frog_adjust;
varying vec3 current_fog_color;

uniform float far;
uniform int current_hour_floor;
uniform int current_hour_ceil;
uniform float current_hour_fract;
uniform float rainStrength;
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;

#if MAKEUP_COLOR == 0
  uniform vec3 skyColor;
#endif

#if MAKEUP_COLOR == 1
  #include "/lib/luma.glsl"
#endif

#include "/lib/basic_utils.glsl"

#if AA_TYPE == 1 || AA_TYPE == 2
  #include "/src/taa_offset.glsl"
#endif

void main() {
  // Simplified light calculation for this basic elements
  vec2 illumination = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  float visible_sky = illumination.y * 1.105 - .10495;

  vec3 direct_light_color =
    texture2D(gaux3, vec2(AMBIENT_X, current_hour)).rgb * (1.0 - rainStrength);

  #if MAKEUP_COLOR == 1
    vec3 hi_sky_color =
      texture2D(gaux3, vec2(HI_SKY_X, current_hour)).rgb;

    direct_light_color = mix(
      direct_light_color,
      HI_SKY_RAIN_COLOR * luma(hi_sky_color),
      rainStrength
    );

    hi_sky_color = mix(
      hi_sky_color,
      HI_SKY_RAIN_COLOR * luma(hi_sky_color),
      rainStrength
    );

  #else
    vec3 hi_sky_color = skyColor;
  #endif

  vec3 omni_light = mix(hi_sky_color, direct_light_color, OMNI_TINT) *
    visible_sky * visible_sky;

  vec3 candle_color = candle_baselight * cube_pow(illumination.x);
  vec3 final_light = (direct_light_color * illumination.y) + candle_color;

  tint_color = gl_Color;
  #include "/src/position_vertex.glsl"
  #include "/src/fog_vertex.glsl"
}
