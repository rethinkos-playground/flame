precision highp float;

// Volume-only pass: raymarches fire + smoke at reduced resolution and
// outputs vec4(accumulated emission, transmittance) for the composite pass.

varying vec2 vUv;

uniform vec3  uCamPos;
uniform mat4  uCamMat;      // camera world matrix (inverse view)
uniform vec2  uFrustum;     // tan(fov/2) * vec2(aspect, 1.0)
uniform float uTime;
uniform float uRand;

uniform vec3  uColorCore;
uniform vec3  uColorEdge;
uniform vec3  uSmokeColor;
uniform float uSize;
uniform float uIntensity;
uniform float uSpeed;
uniform float uRise;
uniform float uTurbulence;
uniform float uWobble;
uniform float uSmoke;
uniform float uBaseY;
uniform int   uSteps;

const int   MAX_STEPS = 96;
const float GROUND_Y  = 0.0;

// ---------- Noise ----------
float hash13(vec3 p3) {
  p3 = fract(p3 * 0.1031);
  p3 += dot(p3, p3.zyx + 31.32);
  return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  float n000 = hash13(i + vec3(0.0, 0.0, 0.0));
  float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
  float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
  float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
  float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
  float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
  float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
  float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
  return mix(
      mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
      mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
      f.z);
}

float fbm(vec3 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 3; i++) {
    v += a * vnoise(p);
    p = p * 2.07 + vec3(1.3, 7.1, 3.7);
    a *= 0.5;
  }
  return v;
}

// ---------- Flame geometry ----------
float flameH() { return 1.62 * uSize; }
float flameR() { return 0.58 * uSize; }

// Dancing sway of the flame axis, stronger near the tip
vec2 axisSway(float y, float t) {
  float w = uWobble * y * y;
  return vec2(
      sin(y * 5.1 - t * 2.0) * 0.55 + sin(y * 11.3 - t * 3.3) * 0.25,
      cos(y * 4.3 - t * 1.6) * 0.55 + cos(y * 9.7 - t * 2.8) * 0.25
  ) * w * flameR();
}

// ---------- Fire field ----------
float fireField(vec3 p, out vec3 emit) {
  emit = vec3(0.0);
  float H = flameH();
  float R = flameR();
  float t = uTime * uSpeed;

  float y = (p.y - uBaseY) / H; // 0 at base, 1 at nominal tip
  if (y < 0.0 || y > 1.25) return 0.0;

  vec2 sway = axisSway(y, t);
  float r = length(p.xz - sway);

  float yc = clamp(y, 0.0, 1.0);
  float Ry = R * (1.0 - pow(yc, 1.35)); // teardrop envelope
  Ry = max(Ry, 0.02 * R);

  float radial = 1.0 - smoothstep(0.0, 1.0, r / Ry);
  float lift   = smoothstep(-0.03, 0.10, y);   // ignition at the base
  float tip    = 1.0 - smoothstep(0.55, 1.08, y);

  float fuel = pow(radial, 1.35) * lift * tip;

  // Rising turbulent detail (stretched vertically into licks)
  vec3 np = vec3(p.xz / uSize * 3.4, (p.y - uBaseY) / uSize * 2.2 - t * uRise);
  float n = fbm(np + vec3(0.0, 0.0, t * 0.35));
  float turb = mix(0.30, 1.80, n);
  float erosion = smoothstep(-0.05, 0.55, y) * uTurbulence;

  float heat = fuel * mix(1.0, turb, erosion);
  heat -= 0.30 * smoothstep(0.35, 1.05, y); // cool toward the tip
  heat = (heat - 0.26) * 1.8;
  heat = max(heat, 0.0);

  float dens = smoothstep(0.0, 0.45, heat);
  float t01 = clamp(heat * 0.75, 0.0, 1.0);

  // Temperature -> color: edge color -> core color -> white hot
  vec3 c = mix(uColorEdge, uColorCore, smoothstep(0.10, 0.85, t01));
  c = mix(c, vec3(1.0), smoothstep(0.88, 1.0, t01) * 0.6);

  float flick = 1.0
      + 0.10 * sin(t * 9.1)
      + 0.05 * sin(t * 21.7 + p.y * 4.0)
      + 0.04 * sin(t * 37.3 + p.x * 3.0);

  emit = c * (0.25 + 2.0 * pow(t01, 1.8)) * uIntensity * flick;
  return dens;
}

// ---------- Smoke field ----------
float smokeField(vec3 p, out vec3 scat) {
  scat = vec3(0.0);
  if (uSmoke <= 0.001) return 0.0;
  float H = flameH();
  float y = (p.y - uBaseY) / H;
  if (y < 0.45 || y > 2.35) return 0.0;
  float t = uTime * uSpeed;

  vec2 sway = axisSway(min(y, 1.0), t);
  vec3 np = vec3(p.xz / uSize * 1.15, (p.y - uBaseY) / uSize * 1.15 - t * uRise * 0.40);
  np.x += sin(t * 0.23) * 0.6; // slow wind drift
  np.z += cos(t * 0.19) * 0.5;
  float n = fbm(np + 47.3);

  float rad = length(p.xz - sway * 0.4);
  float spread = (0.38 + (y - 0.45) * 0.55) * uSize;
  float radial = 1.0 - smoothstep(spread * 0.45, spread * 1.6, rad);
  float band = smoothstep(0.45, 0.95, y) * (1.0 - smoothstep(1.5, 2.35, y));

  float d = smoothstep(0.52, 0.95, n) * radial * band * uSmoke;

  // Smoke lit by the fire below
  float light = exp(-max(y - 0.55, 0.0) * 1.9) * exp(-rad * 1.4 / uSize);
  scat = mix(uSmokeColor, uColorEdge * 1.3 + 0.06, light * 0.9);
  return d;
}

vec2 boxHit(vec3 ro, vec3 rd, vec3 bmin, vec3 bmax) {
  vec3 t0 = (bmin - ro) / rd;
  vec3 t1 = (bmax - ro) / rd;
  vec3 tn = min(t0, t1);
  vec3 tf = max(t0, t1);
  return vec2(max(tn.x, max(tn.y, tn.z)), min(tf.x, min(tf.y, tf.z)));
}

// ---------- Main ----------
void main() {
  vec2 ndc = vUv * 2.0 - 1.0;
  vec3 rdView = normalize(vec3(ndc * uFrustum, -1.0));
  vec3 rd = normalize((uCamMat * vec4(rdView, 0.0)).xyz);
  vec3 ro = uCamPos;

  // Ground occludes the volume
  float tGround = -1.0;
  if (rd.y < -0.0001) tGround = (GROUND_Y - ro.y) / rd.y;

  float H = flameH();
  vec3 bmin = vec3(-1.9 * uSize, uBaseY + 0.002, -1.9 * uSize);
  vec3 bmax = vec3( 1.9 * uSize, uBaseY + 2.4 * H,  1.9 * uSize);
  vec2 tb = boxHit(ro, rd, bmin, bmax);

  vec3 acc = vec3(0.0);
  float trans = 1.0;

  if (tb.y > tb.x) {
    float t0 = max(tb.x, 0.0);
    float t1 = tb.y;
    if (tGround > 0.0) t1 = min(t1, tGround);
    if (t1 > t0) {
      float dt = (t1 - t0) / float(uSteps);
      float jitter = hash13(vec3(gl_FragCoord.xy, uRand));
      float tt = t0 + dt * jitter;
      for (int i = 0; i < MAX_STEPS; i++) {
        if (i >= uSteps || trans < 0.015 || tt > t1) break;
        vec3 p = ro + rd * tt;

        vec3 emit; float df = fireField(p, emit);
        vec3 scat; float ds = smokeField(p, scat);

        float sigF = df * 1.9;
        float sigS = ds * 1.25;
        float sig = sigF + sigS;
        if (sig > 1e-4) {
          vec3 j = emit * sigF + scat * sigS * 0.22;
          float stepT = exp(-sig * dt);
          acc += trans * (j / sig) * (1.0 - stepT);
          trans *= stepT;
        }
        tt += dt;
      }
    }
  }

  gl_FragColor = vec4(acc, trans);
}
