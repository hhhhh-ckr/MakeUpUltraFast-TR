vec3 uchimura(vec3 x) {
  // const float P = 1.0;  // max display brightness
  // const float a = 1.0;  // contrast
  // const float m = 0.22; // linear section start
  // const float l = 0.4;  // linear section length
  // const float c = 1.33; // black
  // const float b = 0.0;  // pedestal

  const float P = 1.0;  // max display brightness
  const float a = 1.2;  // contrast
  const float m = 0.22; // linear section start
  const float l = 0.4;  // linear section length
  const float c = 1.0; // black
  const float b = 0.0;  // pedestal

  float l0 = ((P - m) * l) / a;
  float L0 = m - m / a;
  float L1 = m + (1.0 - m) / a;
  float S0 = m + l0;
  float S1 = m + a * l0;
  float C2 = (a * P) / (P - S1);
  float CP = -C2 / P;

  vec3 w0 = vec3(1.0 - smoothstep(0.0, m, x));
  vec3 w2 = vec3(step(m + l0, x));
  vec3 w1 = vec3(1.0 - w0 - w2);

  vec3 T = vec3(m * pow(x / m, vec3(c)) + b);
  vec3 S = vec3(P - (P - S1) * exp(CP * (x - S0)));
  vec3 L = vec3(m + a * (x - m));

  return T * w0 + L * w1 + S * w2;
}