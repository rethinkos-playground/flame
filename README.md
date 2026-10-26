# 🔥 焰 · FLAME

> Raymarched Volumetric Flame — 基于 **Three.js + TypeScript** 的实时体积火焰动画
>
> 在线体验：**https://rethinkos-playground.github.io/flame/**

纯 GLSL 光线步进（Raymarching）渲染的体积火焰：FBM 噪声侵蚀 + 泪滴形包络 + 温度驱动的黑体色梯度，配合余烬粒子、烟雾、地面光池与 UnrealBloom 泛光，所有参数均可实时调节。

## ✨ 特性

- 🎨 **颜色可调** — 焰心色 / 焰边色双色拾取，内置 6 组预设（经典烈焰、幽蓝冰焰、翡翠毒焰、紫狱冥火、青碧魂火、炽白等离子）
- 📐 **大小可调** — 火焰整体缩放（0.4x ~ 2.4x），噪声频率随尺寸联动，形态比例始终一致
- 🌪 **动态参数** — 燃烧速度、上升速度、湍流侵蚀、轴心摇曳
- ✨ **氛围效果** — 体积烟雾（受火焰照亮）、GPU 余烬火星、地面光池反射、Bloom 泛光、ACES 色调映射
- 🖱 **交互** — 拖拽旋转 / 滚轮缩放 / 自动环绕
- ⚡ **性能** — 射线步进早退、抖动去色带、自适应分辨率降采样

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
├── main.ts                  # 场景、后处理、GUI、渲染循环
├── style.css                # 页面与控制台主题
└── shaders/
    ├── flame.vert.glsl      # 全屏四边形
    ├── flame.frag.glsl      # 体积火焰光线步进（核心）
    ├── ember.vert.glsl      # 余烬粒子（GPU 驱动）
    └── ember.frag.glsl
.github/workflows/deploy.yml # Pages 自动部署
```

## 📜 License

[MIT](./LICENSE)
