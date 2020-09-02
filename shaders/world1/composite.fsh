#version 120
/* MakeUp Ultra Fast - composite.fsh
Render: Tonemap

Javier Garduño - GNU Lesser General Public License v3.0
*/

// 'Global' constants from system
uniform sampler2D colortex0;
uniform ivec2 eyeBrightnessSmooth;
uniform int worldTime;
uniform int current_hour_floor;
uniform int current_hour_ceil;
uniform float current_hour_fract;

// Varyings (per thread shared variables)
varying vec2 texcoord;

#include "/lib/color_utils_end.glsl"
#include "/lib/tone_maps.glsl"

void main() {
  // x: Block, y: Sky ---
  float candle_bright = (eyeBrightnessSmooth.x / 240.0) * .1;

  float current_hour = worldTime / 1000.0;
  float exposure_coef =
    mix(
      ambient_exposure[current_hour_floor],
      ambient_exposure[current_hour_ceil],
      current_hour_fract
    );

  float exposure = ((eyeBrightnessSmooth.y / 240.0) * exposure_coef) + candle_bright;

  // Map from 1.0 - 0.0 to 1.0 - 3.0
  exposure = (exposure * -2.0) + 3.0;

  vec3 color = texture2D(colortex0, texcoord).rgb;

  color *= exposure;
  color = tonemap(color);

  gl_FragData[2] = vec4(color, 1.0);
  gl_FragData[1] = vec4(0.0);  // ¿Performance?
}