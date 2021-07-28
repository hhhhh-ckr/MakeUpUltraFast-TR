/* MakeUp - water.glsl
Water reflection and refraction related functions.
*/

vec3 fast_raymarch(vec3 direction, vec3 hit_coord, inout float infinite, float dither) {
  vec3 hit_pos = camera_to_screen(hit_coord);

  vec3 dir_increment = direction * RAY_STEP;
  vec3 current_march = hit_coord + dir_increment;
  float screen_depth;
  float prev_screen_depth = 0.0;
  float prev_march_pos_z = 0.0;
  float depth_diff;
  vec3 march_pos;
  vec3 last_march_pos;
  vec3 last_hidden_pos;
  bool search_flag = false;
  bool hidden_flag = false;
  bool first_hidden = true;
  bool out_flag = false;

  // Ray marching
  for (int i = 0; i < RAYMARCH_STEPS; i++) {
    last_march_pos = march_pos;
    march_pos = camera_to_screen(current_march);

    if ( // Is outside screen space
      march_pos.x < 0.0 ||
      march_pos.x > 1.0 ||
      march_pos.y < 0.0 ||
      march_pos.y > 1.0
      ) {
        out_flag = true;
      }

    screen_depth = texture2D(depthtex1, march_pos.xy).x;
    depth_diff = screen_depth - march_pos.z;

    if (depth_diff < 0.0 && abs(screen_depth - prev_screen_depth) > abs(march_pos.z - prev_march_pos_z)) {
      hidden_flag = true;
      if (first_hidden) {
        last_hidden_pos = last_march_pos;
        first_hidden = false;
      }
    } else if (hidden_flag && depth_diff > 0.0) {
      hidden_flag = false;
    }

    if (search_flag == false && depth_diff < 0.0 && hidden_flag == false) {
      search_flag = true;
      infinite = 0.0;
    }

    if(search_flag) {
      dir_increment *= .5;
    } else {
      dir_increment *= dither;
    }

    prev_march_pos_z = march_pos.z;
    prev_screen_depth = screen_depth;

    if (hidden_flag) {
      current_march += dir_increment;
    } else {
      current_march += dir_increment * sign(depth_diff);
    }
  }

  if (out_flag) {
    return march_pos;
  } else if (hidden_flag) {
       return last_hidden_pos;
  } else {
    return camera_to_screen(current_march);
  }
}

#if SUN_REFLECTION == 1
  #ifndef NETHER
    #ifndef THE_END

      float sun_reflection(vec3 fragpos) {
        vec3 astro_pos = worldTime > 12900 ? moonPosition : sunPosition;
        float astro_vector =
          max(dot(normalize(fragpos), normalize(astro_pos)), 0.0);

        return clamp(
            smoothstep(
              0.997, 1.0, astro_vector) *
              clamp(4.0 * lmcoord.y - 3.0, 0.0, 1.0) *
              (1.0 - rainStrength),
            0.0,
            1.0
          );
      }

    #endif
  #endif
#endif

vec3 normal_waves(vec3 pos) {
  vec2 wave_1 =
     texture2D(noisetex, (pos.xy * 0.125) + (frameTimeCounter * -.025)).rg;
     wave_1 = wave_1 - .5;
  vec2 wave_2 =
     texture2D(noisetex, (pos.xy * 0.03125) - (frameTimeCounter * .025)).rg;
  wave_2 = wave_2 - .5;
  wave_2 *= 2.0;

  vec2 partial_wave = wave_1 + wave_2;

  vec3 final_wave =
    vec3(partial_wave, 1.0 - (partial_wave.x * partial_wave.x + partial_wave.y * partial_wave.y));

  final_wave.b *= 1.7;

  return normalize(final_wave);

}

vec3 refraction(vec3 fragpos, vec3 color, vec3 refraction) {
  vec3 pos = camera_to_screen(fragpos);

  #if REFRACTION == 1

    float  refraction_strength = 0.1;
    refraction_strength /= 1.0 + length(fragpos) * 0.4;
    vec2 medium_texcoord = pos.xy + refraction.xy * refraction_strength;

    return texture2D(gaux1, medium_texcoord.st).rgb * color;
  #else
    return texture2D(gaux1, pos.xy).rgb * color;
  #endif
}

vec3 get_normals(vec3 bump) {
  float NdotE = abs(dot(water_normal, normalize(position2.xyz)));

  bump *= vec3(NdotE) + vec3(0.0, 0.0, 1.0 - NdotE);

  mat3 tbn_matrix = mat3(
    tangent.x, binormal.x, water_normal.x,
    tangent.y, binormal.y, water_normal.y,
    tangent.z, binormal.z, water_normal.z
    );

  return normalize(bump * tbn_matrix);
}

vec4 reflection_calc(vec3 fragpos, vec3 normal, vec3 reflected, inout float infinite, float dither) {
  #if SSR_TYPE == 0  // Flipped image
    vec3 reflected_vector = reflected * 35.0;
    vec3 pos = camera_to_screen(fragpos + reflected_vector);
  #else  // Raymarch
    vec3 reflected_vector = reflect(normalize(fragpos), normal);
    vec3 pos = fast_raymarch(reflected_vector, fragpos, infinite, dither);
  #endif

  float border =
    clamp((1.0 - (max(0.0, abs(pos.y - 0.5)) * 2.0)) * 50.0, 0.0, 1.0);

  border = clamp(border - pow(pos.y, 10.0), 0.0, 1.0);

  pos.x = abs(pos.x);
  if (pos.x > 1.0) {
    pos.x = 1.0 - (pos.x - 1.0);
  }

  return vec4(texture2D(gaux1, pos.xy).rgb, border);
}

vec3 water_shader(
  vec3 fragpos,
  vec3 normal,
  vec3 color,
  vec3 sky_reflect,
  vec3 reflected,
  float fresnel,
  float dither) {
  vec4 reflection = vec4(0.0);
  float infinite = 1.0;

  #if REFLECTION == 1
    reflection = reflection_calc(fragpos, normal, reflected, infinite, dither);
  #endif

  #ifdef NETHER
    float visible_sky = 0.0;
  #endif

  reflection.rgb = mix(
    sky_reflect * pow(visible_sky, 10.0),
    reflection.rgb,
    reflection.a
  );

  vec3 test = reflection.rgb;

  #if SUN_REFLECTION == 1
     #ifndef NETHER
       #ifndef THE_END
         return mix(color, reflection.rgb, fresnel * .75) +
           vec3(sun_reflection(reflect(normalize(fragpos), normal))) * infinite;
       #else
          return mix(color, reflection.rgb, fresnel * .75);
       #endif
     #else
        return mix(color, reflection.rgb, fresnel * .75);
     #endif
  #else
     return mix(color, reflection.rgb, fresnel * .75);
  #endif
}

//  GLASS

vec4 cristal_reflection_calc(vec3 fragpos, vec3 normal, inout float infinite, float dither) {
  #if SSR_TYPE == 0
    vec3 reflected_vector = reflect(normalize(fragpos), normal) * 35.0;
    vec3 pos = camera_to_screen(fragpos + reflected_vector);
  #else
    vec3 reflected_vector = reflect(normalize(fragpos), normal);
    vec3 pos = fast_raymarch(reflected_vector, fragpos, infinite, dither);

    if (pos.x > 99.0) { // Fallback
      pos = camera_to_screen(fragpos + (reflected_vector * 35.0));
    }
  #endif

  float border_x = max(-fourth_pow(abs(2.0 * pos.x - 1.0)) + 1.0, 0.0);
  float border_y = max(-fourth_pow(abs(2.0 * pos.y - 1.0)) + 1.0, 0.0);
  float border = min(border_x, border_y);

  return vec4(texture2D(gaux1, pos.xy, 0.0).rgb, border);
}

vec4 cristal_shader(
  vec3 fragpos,
  vec3 normal,
  vec4 color,
  vec3 sky_reflection,
  float fresnel,
  float dither)
{
  vec4 reflection = vec4(0.0);
  float infinite = 0.0;

  #if REFLECTION == 1
    reflection = cristal_reflection_calc(fragpos, normal, infinite, dither);
  #endif

  reflection.rgb = mix(sky_reflection * lmcoord.y * lmcoord.y, reflection.rgb, reflection.a);

  color.rgb = mix(color.rgb, sky_reflection, fresnel);
  color.rgb = mix(color.rgb, reflection.rgb, fresnel);

  color.a = mix(color.a, 1.0, fresnel * .9);

  #if SUN_REFLECTION == 1
     #ifndef NETHER
      #ifndef THE_END
        return color +
          vec4(
            mix(
              vec3(sun_reflection(reflect(normalize(fragpos), normal)) * 0.75 * infinite),
              vec3(0.0),
              reflection.a
            ),
            0.0
          );
      #else
        return color;
      #endif
    #else
      return color;
    #endif
  #else
    return color;
  #endif
}
