#version 120
/* MakeUp Ultra Fast - composite.fsh
Render: Horizontal blur pass

Javier Garduño - GNU Lesser General Public License v3.0
*/

#define DOF 1  // [0 1] Enables depth of field (high performance cost)

#if DOF == 1
  uniform sampler2D gaux1;
  uniform float pixelSizeX;
  uniform float viewWidth;
#else
  uniform sampler2D colortex0;
#endif

// Varyings (per thread shared variables)
varying vec2 texcoord;

#if DOF == 1
  // varying float dofDistance;
  #include "/lib/blur.glsl"
#endif

void main() {
  #if DOF == 1
    vec4 color_blur = texture2D(gaux1, texcoord);
    float blur_radius = color_blur.a;
    vec3 color = color_blur.rgb;

    if (blur_radius > 0.5) {
      float radius_inv = 1.0 / blur_radius;
      float weight;
      vec4 new_blur;

      vec4 average = vec4(0.0);
      float start  = max(texcoord.x - blur_radius * pixelSizeX,       pixelSizeX * 0.5);
      float finish = min(texcoord.x + blur_radius * pixelSizeX, 1.0 - pixelSizeX * 0.5);
      float step = pixelSizeX * .5;
      if (blur_radius > 3.0) {
        step *= 4.0;
      } else if (blur_radius > 1.0) {
        step *= 2.0;
      }

      for (float x = start; x <= finish; x += step) {  // step
        weight = fogify((x - texcoord.x) * viewWidth * radius_inv, 0.35);
        new_blur = texture2D(gaux1, vec2(x, texcoord.y));
        average.rgb += new_blur.rgb * weight;
        average.a += weight;
      }
      color = average.rgb / average.a;
    }
  #else
    vec3 color = texture2D(colortex0, texcoord).rgb;
  #endif

  #if DOF == 1
    gl_FragData[4] = vec4(color, blur_radius);
  #else
    gl_FragData[0] = vec4(color, 1.0);
  #endif
  gl_FragData[1] = vec4(0.0);  // ¿Performance?
}