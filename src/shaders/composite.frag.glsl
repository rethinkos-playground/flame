precision highp float;

// Full-resolution composite pass: cheap background (sky + ground), the
// half-resolution volume result, halo glow and vignette.

varying vec2 vUv;

uniform sampler2D uVolume;
uniform vec3  uCamPos;
uniform mat4  uCamMat;
uniform vec2  uFrustum;
uniform float uTime;
uniform vec3  uColorCore;
uniform vec3  uColorEdge;
uniform float uSize;
uniform float uIntensity;
uniform float uSpeed;
uniform float uGlow;
uniform float uBaseY;

float hash13(vec3 p3) {
  p3 = fract(p3 * 0.1031);
  p3 += dot(p3, p3.zyx + 31.32);
  return fract((p3.x + p3.y) * p3.z);
}

vec3 skyColor(vec3 rd) {
  float h = clamp(rd.y * 0.5 + 0.5, 0.0, 1.0);
  return mix(vec3(0.045, 0.035, 0.042), vec3(0.008, 0.009, 0.018), pow(h, 0.7));
}

vec3 groundColor(vec3 gp, vec3 rd) {
  float dAxis = length(gp.xz);
  float t = uTime * uSpeed;
  float flick = 1.0 + 0.12 * sin(t * 9.1) + 0.05 * sin(t * 23.0);
  vec3 lightCol = mix(uColorEdge, uColorCore, 0.35);

  float atten = 1.0 / (1.0 + pow(dAxis / (1.1 * uSize), 2.0) * 3.2);
  float grain = hash13(vec3(floor(gp.xz * 70.0), 3.0)) * 0.016;
  vec3 base = vec3(0.028, 0.026, 0.031) + grain;

  vec3 c = base + lightCol * atten * 0.22 * uIntensity * flick;

  // Fake reflected glow pool right under the flame
  float pool = exp(-dAxis * 3.0 / uSize) * 0.05 * uIntensity * flick;
  c += lightCol * pool;

  float dist = length(gp - uCamPos);
  float fog = clamp(1.0 - exp(-max(dist - 5.0, 0.0) * 0.14), 0.0, 1.0);
  return mix(c, skyColor(rd) * 1.2, fog);
}

void main() {
  vec2 ndc = vUv * 2.0 - 1.0;
  vec3 rdView = normalize(vec3(ndc * uFrustum, -1.0));
  vec3 rd = normalize((uCamMat * vec4(rdView, 0.0)).xyz);
  vec3 ro = uCamPos;

  // Background: sky + ground
  vec3 bg = skyColor(rd);
  if (rd.y < -0.0001) {
    float tGround = (0.0 - ro.y) / rd.y;
    if (tGround > 0.0) bg = groundColor(ro + rd * tGround, rd);
  }

  // Composite the (half-res) volume over the background
  vec4 vol = texture2D(uVolume, vUv);
  vec3 col = bg * vol.a + vol.rgb;

  // Additive halo glow around the flame body
  float t = uTime * uSpeed;
  float flick = 1.0 + 0.10 * sin(t * 9.1) + 0.05 * sin(t * 21.7);
  float H = 1.62 * uSize;
  vec3 c1 = vec3(0.0, uBaseY + H * 0.22, 0.0);
  vec3 c2 = vec3(0.0, uBaseY + H * 0.68, 0.0);
  float tc1 = max(dot(c1 - ro, rd), 0.0);
  float tc2 = max(dot(c2 - ro, rd), 0.0);
  float d1 = length(ro + rd * tc1 - c1) / uSize;
  float d2 = length(ro + rd * tc2 - c2) / uSize;
  float g = exp(-d1 * 3.2) * 0.40 + exp(-d2 * 4.6) * 0.25;
  vec3 glowCol = mix(uColorEdge, uColorCore, 0.3);
  col += glowCol * g * uGlow * uIntensity * flick * (0.25 + 0.75 * vol.a);

  // Vignette
  float vig = 1.0 - 0.32 * dot(ndc * 0.55, ndc * 0.55);
  col *= clamp(vig, 0.0, 1.0);

  gl_FragColor = vec4(col, 1.0);
}
