attribute float aSeed;
attribute float aSize;

uniform float uTime;
uniform float uSpeed;
uniform float uHeight;
uniform float uRadius;
uniform float uPixelRatio;

varying float vLife;
varying float vSeed;

void main() {
  float life = fract(aSeed + uTime * uSpeed * (0.045 + 0.05 * aSeed));
  vLife = life;
  vSeed = aSeed;

  float ang = aSeed * 57.0 + life * (1.2 + fract(aSeed * 31.0) * 4.0) + uTime * 0.1;
  float rad = uRadius * (0.22 + 1.75 * life) * (0.35 + 0.9 * fract(aSeed * 13.7));
  vec3 pos = vec3(
      cos(ang) * rad,
      life * uHeight * (0.5 + 0.85 * fract(aSeed * 7.3)),
      sin(ang) * rad);
  pos.x += sin(uTime * 1.6 + aSeed * 91.0) * life * 0.22 * uRadius;
  pos.z += cos(uTime * 1.25 + aSeed * 73.0) * life * 0.22 * uRadius;

  vec4 mv = modelViewMatrix * vec4(pos, 1.0);
  gl_Position = projectionMatrix * mv;
  gl_PointSize = aSize * uPixelRatio * (10.0 / max(-mv.z, 0.1)) * (1.0 - 0.55 * life);
}
