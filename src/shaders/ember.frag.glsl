precision highp float;

uniform vec3 uColorCore;
uniform vec3 uColorEdge;
uniform float uOpacity;

varying float vLife;
varying float vSeed;

void main() {
  float m = 1.0 - smoothstep(0.20, 0.50, length(gl_PointCoord - vec2(0.5)));
  if (m < 0.02) discard;
  float fade = smoothstep(0.0, 0.10, vLife) * (1.0 - smoothstep(0.35, 1.0, vLife));
  vec3 c = mix(uColorCore, uColorEdge, clamp(vLife * 1.5 + vSeed * 0.25, 0.0, 1.0));
  gl_FragColor = vec4(c * (1.2 * fade * m * uOpacity), 1.0);
}
