import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';
import { OutputPass } from 'three/examples/jsm/postprocessing/OutputPass.js';
import GUI from 'lil-gui';

import flameVert from './shaders/flame.vert.glsl?raw';
import flameFrag from './shaders/flame.frag.glsl?raw';
import emberVert from './shaders/ember.vert.glsl?raw';
import emberFrag from './shaders/ember.frag.glsl?raw';

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
const DEFAULTS = {
  colorCore: '#ffe6b8',
  colorEdge: '#ff4d00',
  size: 1.0,
  intensity: 1.1,
  turbulence: 0.62,
  wobble: 0.07,
  speed: 1.0,
  rise: 2.4,
  smoke: 0.55,
  embers: true,
  bloom: 0.75,
  autoRotate: true,
};
const params = { ...DEFAULTS };

const PRESETS: Array<{ name: string; core: string; edge: string }> = [
  { name: '经典烈焰', core: '#ffe6b8', edge: '#ff4d00' },
  { name: '幽蓝冰焰', core: '#eaf7ff', edge: '#1e6dff' },
  { name: '翡翠毒焰', core: '#f2ffd9', edge: '#22ff66' },
  { name: '紫狱冥火', core: '#ffe3fb', edge: '#9d2bff' },
  { name: '青碧魂火', core: '#e6fffb', edge: '#00ffc3' },
  { name: '炽白等离子', core: '#ffffff', edge: '#ffab3d' },
];

// ---------------------------------------------------------------------------
// Renderer / scene / camera
// ---------------------------------------------------------------------------
const canvas = document.getElementById('app') as HTMLCanvasElement;
const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: false,
  powerPreference: 'high-performance',
});
let dpr = Math.min(window.devicePixelRatio || 1, 1.75);
renderer.setPixelRatio(dpr);
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.05;

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(
  50,
  window.innerWidth / window.innerHeight,
  0.1,
  60
);
camera.position.set(0.25, 1.2, 3.7);

const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 0.8, 0);
controls.enableDamping = true;
controls.dampingFactor = 0.06;
controls.enablePan = false;
controls.minDistance = 1.6;
controls.maxDistance = 9;
controls.maxPolarAngle = Math.PI * 0.495;
controls.autoRotate = params.autoRotate;
controls.autoRotateSpeed = 0.55;

// ---------------------------------------------------------------------------
// Flame — fullscreen raymarched volume
// ---------------------------------------------------------------------------
const colorCore = new THREE.Color(params.colorCore);
const colorEdge = new THREE.Color(params.colorEdge);
const smokeColor = new THREE.Color();

const uniforms = {
  uCamPos: { value: new THREE.Vector3() },
  uCamMat: { value: new THREE.Matrix4() },
  uFrustum: { value: new THREE.Vector2() },
  uTime: { value: 0 },
  uRand: { value: 0 },
  uColorCore: { value: colorCore },
  uColorEdge: { value: colorEdge },
  uSmokeColor: { value: smokeColor },
  uSize: { value: params.size },
  uIntensity: { value: params.intensity },
  uSpeed: { value: params.speed },
  uRise: { value: params.rise },
  uTurbulence: { value: params.turbulence },
  uWobble: { value: params.wobble },
  uSmoke: { value: params.smoke },
  uGlow: { value: 0.55 },
  uBaseY: { value: 0 },
};

const flameQuad = new THREE.Mesh(
  new THREE.PlaneGeometry(2, 2),
  new THREE.ShaderMaterial({
    vertexShader: flameVert,
    fragmentShader: flameFrag,
    uniforms,
    depthTest: false,
    depthWrite: false,
  })
);
flameQuad.frustumCulled = false;
flameQuad.renderOrder = -10;
scene.add(flameQuad);

// ---------------------------------------------------------------------------
// Embers — GPU-driven rising sparks
// ---------------------------------------------------------------------------
const EMBER_COUNT = 300;
const emberGeometry = new THREE.BufferGeometry();
{
  const pos = new Float32Array(EMBER_COUNT * 3);
  const seeds = new Float32Array(EMBER_COUNT);
  const sizes = new Float32Array(EMBER_COUNT);
  for (let i = 0; i < EMBER_COUNT; i++) {
    seeds[i] = Math.random();
    sizes[i] = 1.0 + Math.random() * 2.6;
  }
  emberGeometry.setAttribute('position', new THREE.BufferAttribute(pos, 3));
  emberGeometry.setAttribute('aSeed', new THREE.BufferAttribute(seeds, 1));
  emberGeometry.setAttribute('aSize', new THREE.BufferAttribute(sizes, 1));
}

const emberUniforms = {
  uTime: { value: 0 },
  uSpeed: { value: params.speed },
  uHeight: { value: 1.62 * params.size },
  uRadius: { value: 0.52 * params.size },
  uPixelRatio: { value: dpr },
  uColorCore: { value: colorCore },
  uColorEdge: { value: colorEdge },
  uOpacity: { value: 1 },
};

const embers = new THREE.Points(
  emberGeometry,
  new THREE.ShaderMaterial({
    vertexShader: emberVert,
    fragmentShader: emberFrag,
    uniforms: emberUniforms,
    transparent: true,
    blending: THREE.AdditiveBlending,
    depthTest: false,
    depthWrite: false,
  })
);
embers.frustumCulled = false;
embers.renderOrder = 10;
scene.add(embers);

// ---------------------------------------------------------------------------
// Post-processing
// ---------------------------------------------------------------------------
const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
const bloomPass = new UnrealBloomPass(
  new THREE.Vector2(window.innerWidth, window.innerHeight),
  params.bloom,
  0.55,
  0.8
);
composer.addPass(bloomPass);
composer.addPass(new OutputPass());

// ---------------------------------------------------------------------------
// Parameter sync
// ---------------------------------------------------------------------------
function syncParams() {
  colorCore.setStyle(params.colorCore);
  colorEdge.setStyle(params.colorEdge);
  smokeColor.copy(colorEdge).multiplyScalar(0.2).addScalar(0.012);

  uniforms.uSize.value = params.size;
  uniforms.uIntensity.value = params.intensity;
  uniforms.uSpeed.value = params.speed;
  uniforms.uRise.value = params.rise;
  uniforms.uTurbulence.value = params.turbulence;
  uniforms.uWobble.value = params.wobble;
  uniforms.uSmoke.value = params.smoke;

  emberUniforms.uSpeed.value = params.speed;
  emberUniforms.uHeight.value = 1.62 * params.size;
  emberUniforms.uRadius.value = 0.52 * params.size;
  embers.visible = params.embers;

  bloomPass.strength = params.bloom;
  controls.autoRotate = params.autoRotate;
}
syncParams();

// ---------------------------------------------------------------------------
// GUI
// ---------------------------------------------------------------------------
const gui = new GUI({ title: '🔥 火焰控制台', width: 300 });

const presetHost: Record<string, () => void> = {};
for (const p of PRESETS) {
  presetHost[p.name] = () => {
    params.colorCore = p.core;
    params.colorEdge = p.edge;
    syncParams();
    gui.controllersRecursive().forEach((c) => c.updateDisplay());
  };
}

const fColor = gui.addFolder('🎨 颜色');
fColor.addColor(params, 'colorCore').name('焰心色').onChange(syncParams);
fColor.addColor(params, 'colorEdge').name('焰边色').onChange(syncParams);
for (const p of PRESETS) fColor.add(presetHost, p.name).name(`✦ ${p.name}`);

const fShape = gui.addFolder('📐 形态');
fShape.add(params, 'size', 0.4, 2.4, 0.01).name('大小').onChange(syncParams);
fShape
  .add(params, 'intensity', 0.2, 2.5, 0.01)
  .name('强度')
  .onChange(syncParams);
fShape
  .add(params, 'turbulence', 0, 1.2, 0.01)
  .name('湍流')
  .onChange(syncParams);
fShape
  .add(params, 'wobble', 0, 0.25, 0.005)
  .name('摇曳')
  .onChange(syncParams);

const fMotion = gui.addFolder('🌪 动态');
fMotion.add(params, 'speed', 0.2, 2.5, 0.01).name('燃烧速度').onChange(syncParams);
fMotion.add(params, 'rise', 0.6, 4.5, 0.01).name('上升速度').onChange(syncParams);

const fFx = gui.addFolder('✨ 效果');
fFx.add(params, 'smoke', 0, 1.5, 0.01).name('烟雾').onChange(syncParams);
fFx.add(params, 'embers').name('余烬火星').onChange(syncParams);
fFx.add(params, 'bloom', 0, 2, 0.01).name('泛光').onChange(syncParams);
fFx.add(params, 'autoRotate').name('自动旋转').onChange(syncParams);

gui
  .add(
    {
      reset: () => {
        Object.assign(params, DEFAULTS);
        syncParams();
        gui.controllersRecursive().forEach((c) => c.updateDisplay());
      },
    },
    'reset'
  )
  .name('↺ 重置参数');

if (window.innerWidth < 720) gui.close();

// ---------------------------------------------------------------------------
// Resize (+ adaptive resolution)
// ---------------------------------------------------------------------------
function onResize() {
  const w = window.innerWidth;
  const h = window.innerHeight;
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setPixelRatio(dpr);
  renderer.setSize(w, h);
  composer.setSize(w, h);
  emberUniforms.uPixelRatio.value = dpr;
}
window.addEventListener('resize', onResize);
onResize();

// ---------------------------------------------------------------------------
// Render loop
// ---------------------------------------------------------------------------
const tanHalf = Math.tan(THREE.MathUtils.degToRad(camera.fov * 0.5));

function updateCameraUniforms() {
  camera.updateMatrixWorld();
  uniforms.uCamPos.value.copy(camera.position);
  uniforms.uCamMat.value.copy(camera.matrixWorld);
  uniforms.uFrustum.value.set(tanHalf * camera.aspect, tanHalf);
}

const clock = new THREE.Clock();
let time = 0;
let frames = 0;
let fpsAcc = 0;
let firstFrame = true;

function tick() {
  requestAnimationFrame(tick);
  const dt = Math.min(clock.getDelta(), 0.05);
  time += dt;

  controls.update();
  uniforms.uTime.value = time;
  uniforms.uRand.value = Math.random();
  emberUniforms.uTime.value = time;
  updateCameraUniforms();
  composer.render();

  if (firstFrame) {
    firstFrame = false;
    document.getElementById('loader')?.classList.add('done');
  }

  // Adaptive resolution: step down pixel ratio when FPS stays low
  frames++;
  fpsAcc += dt;
  if (fpsAcc >= 2) {
    const fps = frames / fpsAcc;
    if (fps < 42 && dpr > 1) {
      dpr = Math.max(1, dpr - 0.25);
      onResize();
    }
    frames = 0;
    fpsAcc = 0;
  }
}
tick();
