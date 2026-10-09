# Flutter 液态玻璃 SDK 设计文档

日期：2026-10-09
状态：已确认

## 目标

一个纯 Dart 的 Flutter package，用 `FragmentShader`（GLSL，经 Impeller 编译）在 Flutter 端实现接近 iOS 26 Liquid Glass 的液态玻璃效果，默认风格为「清透型」（折射透镜感强、轻模糊、边缘高光）。

### 已确认的关键决策

| 问题 | 决策 |
|---|---|
| 效果范围 | 完整液态玻璃：折射 + 边缘高光 + 模糊 + 按压/拖拽形变 |
| 技术路径 | 纯 Flutter `FragmentShader` + `BackdropFilter`，无平台通道 |
| 目标平台 | iOS、Android（Impeller） |
| 交互动效 | 完整交互：按压凹陷 + 拖拽黏滞形变 + 弹簧回弹 |
| API 形态 | 核心容器 Widget + 预置组件（Button / Card / NavigationBar） |
| 性能策略 | 手动质量档 `LiquidGlassQuality.high/medium/low`，无自动降级 |
| 默认视觉风格 | 清透型（≈ iOS 26 默认观感） |
| 渲染管线 | 双层 BackdropFilter：引擎 blur（内）+ 自定义 shader（外） |

## 渲染管线

嵌套两层 backdrop filter，clip 到同一圆角矩形：

1. **内层** `BackdropFilter(ImageFilter.blur)`：背景模糊交给引擎。Impeller 的模糊有降采样优化，成本近似恒定。质量档降级时调 blur sigma。
2. **外层** `BackdropFilter(ImageFilter.shader)`：自定义 shader 采样到的背景即内层模糊后的结果，负责折射 UV 扰动、菲涅尔边缘高光、色调/饱和叠加、按压拖拽形变。

不采用的方案：单 pass 全 shader（模糊多次采样太贵）；`RepaintBoundary.toImage()` 手动抓背景（每帧位图开销大、背景动画同步复杂）。

## 模块划分

```
liquid_glass/
├── shaders/
│   └── liquid_glass.frag          # 唯一自定义 shader
├── lib/
│   ├── liquid_glass.dart          # 对外出口，只 export 公共 API
│   └── src/
│       ├── liquid_glass.dart      # 核心容器 Widget（双层 BackdropFilter）
│       ├── liquid_glass_controller.dart  # 按压/拖拽形变状态，ChangeNotifier
│       ├── liquid_glass_shader.dart      # FragmentProgram 加载缓存 + uniform 绑定
│       ├── liquid_glass_geometry.dart    # 圆角矩形 SDF 参数
│       ├── quality.dart           # LiquidGlassQuality 与参数映射
│       └── widgets/
│           ├── liquid_glass_button.dart
│           ├── liquid_glass_card.dart
│           └── liquid_glass_navigation_bar.dart
├── example/                       # 演示 App
└── test/                          # 单测 + Widget 测试
```

分层职责：

- **引擎层**：内层 blur。
- **Shader 层**：折射、高光、色调、形变。
- **Controller 层**：手势 → uniform（触摸位置、按压量、拖拽速度），弹簧回弹动画。
- **Widget 层**：组合以上三者；预置组件为核心容器的参数化封装。

隔离点：`liquid_glass_shader.dart` 是唯一接触 `FragmentShader` API 的模块，未来可替换为原生实现。

## Shader 算法（liquid_glass.frag）

按像素依次计算：

1. **形状与 SDF**：`d = sdRoundedBox(uv, size, radius)`。`d` 用于形状裁剪、边缘环带（`d ∈ [-edgeWidth, 0]`）计算、折射法线推导。
2. **折射**：边缘环带内以 SDF 梯度为表面法线：
   ```glsl
   vec2 normal = normalize(grad(sdf));
   float height = smoothstep(0.0, -edgeWidth, d);
   vec2 refractUV = uv + normal * height * refractionStrength;
   vec3 bg = texture(uBackdrop, refractUV).rgb;
   ```
   视觉：背景在玻璃边缘弯折、中心轻微放大。`refractionStrength` 对外暴露。
3. **菲涅尔边缘高光**：`1 - height` 加权亮边，乘光方向权重模拟高光带。参数 `highlightIntensity`。
4. **色调与饱和**：半透明 tint 叠加（默认 8% 白）+ 轻微 saturate 提升。
5. **形变**：uniform 传入 `uTouchPoint`、`uPressAmount`(0~1)、`uDragVelocity`。
   - 按压：以触摸点为中心的径向场对 SDF 做凹陷偏移（`d += press * gauss(uv - touch)`）。
   - 拖拽：沿速度方向拉伸圆角矩形 SDF（黏滞形变）。
   - 回弹：Controller 用弹簧动画衰减 uniform，shader 不感知动画逻辑。

质量档在 shader 中：high = 折射 + 高光全开；medium = 弱折射 + 简化高光；low = shader 仅做 tint 叠加（一次纹理采样），折射/高光/形变全关。

## 公共 API

### 核心容器

```dart
LiquidGlass({
  required Widget child,
  // 外观
  double borderRadius = 20,
  Color tint = const Color(0x14FFFFFF),
  double refractionStrength = 1.0,   // 0~2
  double highlightIntensity = 1.0,   // 0~2
  double blurSigma = 12,
  // 交互
  bool interactive = true,
  LiquidGlassController? controller,
  // 性能
  LiquidGlassQuality quality = LiquidGlassQuality.high,
  EdgeInsetsGeometry padding, VoidCallback? onTap, ...
})
```

### 预置组件

```dart
LiquidGlassButton({ required Widget child, VoidCallback? onPressed, ... })
// interactive=true，按压凹陷反馈，圆角 24

LiquidGlassCard({ required Widget child, ... })
// interactive=false，圆角 20，可选阴影

LiquidGlassNavigationBar({ required List<Widget> items, int currentIndex, ... })
// interactive=false，圆角胶囊形
```

### Controller

```dart
class LiquidGlassController extends ChangeNotifier {
  double pressAmount;
  Offset? touchPoint;
  Offset dragVelocity;
  void press(Offset at);
  void release();  // 弹簧回弹
}
```

### 质量档

```dart
enum LiquidGlassQuality {
  high,    // blurSigma 原值 + 折射 + 高光 + 形变
  medium,  // blurSigma × 0.7 + 弱折射 + 简高光 + 形变
  low,     // blurSigma × 0.5，shader 仅 tint，无折射/高光/形变
}
```

规则：`quality` 只做乘性降级，不覆盖用户显式传入的参数（显式传参优先）。所有效果参数默认值即「清透型」观感。

## 性能策略

- 模糊交引擎（降采样优化），shader 不做多次采样模糊。
- shader 降级通过 `uFlags` uniform 控制开关，low 档近似一次纹理采样。
- `FragmentProgram` 全局加载一次并缓存。
- 无交互时 Controller 不产生帧回调，形变 uniform 恒为 0，不重绘。
- 核心容器内置 `RepaintBoundary` 隔离重绘范围。
- README 写明降级建议（按设备分档）与已知限制（大面积全屏玻璃 + 高 blur sigma 在低端 Android 有压力，建议 low 档）。

## 测试方案

- **单元测试**：质量档参数映射、SDF 几何参数、Controller 状态机（press/drag/release、弹簧收敛）。
- **Widget 测试**：核心容器与预置组件的构建、参数透传、手势 → Controller 联动。
- **Golden 测试**：只对组件结构（圆角、padding、布局）做 golden。shader 视觉效果以 example App 人工验证为准——Flutter golden test 环境不运行真实 Impeller shader。
- **example App**：滚动彩色渐变 + 网格背景上叠三种组件，含质量档切换开关，用于人工观感与性能验证。

## 开发顺序

1. 包骨架 + shader 加载
2. 核心容器（静态折射 + 高光）
3. 质量档
4. Controller 形变交互
5. 预置组件
6. example + 测试
