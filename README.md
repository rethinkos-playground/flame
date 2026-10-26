# 🔥 焰 · FLAME

> Raymarched Volumetric Flame — 基于 **Three.js + TypeScript** 的实时体积火焰动画
>
> 在线体验：**https://rethinkos-playground.github.io/flame/**

纯 GLSL 光线步进（Raymarching）渲染的体积火焰：FBM 噪声侵蚀 + 泪滴形包络 + 温度驱动的黑体色梯度，配合余烬粒子、烟雾、地面光池与 UnrealBloom 泛光，所有参数均可实时调节。

## ✨ 特性

- 🎨 **颜色可调** — 焰心色 / 焰边色双色拾取（黑体辐射式四段色带：暗红余烬 → 焰边 → 焰心 → 白热），内置 6 组预设（经典烈焰、幽蓝冰焰、翡翠毒焰、紫狱冥火、青碧魂火、炽白等离子）
- 📐 **大小可调** — 火焰整体缩放（0.4x ~ 2.4x），噪声频率随尺寸联动，形态比例始终一致
- 🌪 **拟真形态** — 参考 [Inigo Quilez 的 domain warping](https://iquilezles.org/articles/warp/)：ridged 噪声折叠域产生卷曲火舌；浮力加速平流让焰尖拉伸加速；螺旋 swirl + 高频轮廓侵蚀打破光滑锥体；全局燃料脉动模拟"呼吸"
- ✨ **氛围效果** — 体积烟雾（受火焰照亮）、GPU 余烬火星、地面光池反射、Bloom 泛光、ACES 色调映射
- 🖱 **交互** — 拖拽旋转 / 滚轮缩放 / 自动环绕；URL 参数 `?q=高|中|低&auto=0` 可锁定画质
- ⚡ **性能** — 体积光线步进在半分辨率 HDR target 中渲染后全分辨率合成（像素量 ÷4）、FBM 3 octaves、步进早退 + 抖动去色带、画质三档（96/72/48 步）+ FPS 自适应降档 + 自适应 DPR

## 🛠 技术栈

| 层 | 技术 |
| --- | --- |
| 渲染 | [three.js](https://threejs.org/)（WebGL2 + GLSL raymarching） |
| 语言 | TypeScript (strict) |
| 构建 | Vite |
| UI | lil-gui |
| 部署 | GitHub Actions → GitHub Pages（push 即自动部署） |

## 🚀 本地开发

```bash
npm install
npm run dev      # 开发服务器
npm run build    # 类型检查 + 生产构建
npm run preview  # 预览构建产物
```

## 📁 结构

```
src/
├── main.ts                  # 场景、两阶段渲染管线、GUI、渲染循环
├── style.css                # 页面与控制台主题
└── shaders/
    ├── flame.vert.glsl      # 全屏四边形
    ├── flame.frag.glsl      # 体积火焰光线步进（半分辨率，核心）
    ├── composite.frag.glsl  # 全分辨率合成（背景/地面/光晕/暗角）
    ├── ember.vert.glsl      # 余烬粒子（GPU 驱动）
    └── ember.frag.glsl
.github/workflows/deploy.yml # Pages 自动部署
```

## 📜 License

[MIT](./LICENSE)
