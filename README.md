# liquid_glass

一个纯 Dart 的 Flutter package，用 `FragmentShader`（GLSL，经 Impeller 编译）+
双层 `BackdropFilter` 实现接近 iOS 26 Liquid Glass 的液态玻璃效果：折射透镜、
菲涅尔边缘高光、背景模糊，以及按压凹陷 / 拖拽黏滞形变 / 弹簧回弹交互。

默认视觉风格为「清透型」：折射透镜感强、轻模糊、边缘高光。

## 渲染管线

圆角裁剪（`ClipRRect`）内嵌套两层 backdrop filter：

1. 内层 `BackdropFilter(ImageFilter.blur)`：背景模糊交给引擎（Impeller 降采样优化）。
2. 外层 `BackdropFilter(ImageFilter.shader)`：采样到的背景即内层模糊后的结果，
   负责折射 UV 扰动、边缘高光、色调/饱和叠加与按压/拖拽形变。

## 用法

```dart
import 'package:liquid_glass/liquid_glass.dart';

LiquidGlass(
  borderRadius: 20,
  quality: LiquidGlassQuality.high,
  child: Text('Hello glass'),
)

LiquidGlassButton(onPressed: () {}, child: Text('OK'))

LiquidGlassCard(child: ...)

LiquidGlassNavigationBar(
  items: [Icon(Icons.home), Icon(Icons.search), Icon(Icons.person)],
  currentIndex: _index,
  onItemSelected: (i) => setState(() => _index = i),
)
```

## 质量档与降级建议

`LiquidGlassQuality` 只做乘性降级；显式传入的参数优先于质量档默认值。

| 档位 | blur sigma | 折射 | 高光 | 形变 |
|---|---|---|---|---|
| high | ×1.0 | 全开 | 全开 | 开 |
| medium | ×0.7 | 弱（×0.5） | 简化（×0.5） | 开 |
| low | ×0.5 | 关 | 关 | 关（shader 仅 tint，近似一次纹理采样） |

建议：旗舰设备用 high；中端 Android 用 medium；低端 Android 或大面积
（接近全屏）玻璃 + 高 blur sigma 的场景用 low。

## 已知限制

- 依赖 Impeller 的 runtime effect 编译；Skia（如部分旧 Android / Web）下
  shader 可能无法编译，此时自动退化为仅 blur。
- 大面积全屏玻璃 + 高 blur sigma 在低端 Android 上有压力，请使用 low 档。
- golden test 环境不运行真实 Impeller shader，shader 视觉效果请用
  `example/` App 人工验证。
