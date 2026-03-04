# 构建与视觉规范：主题颜色管理 (Theme Color Management)

本文档补充并修正了 `VISUAL_SKIN_STAND.md` 中关于颜色注入的设计规范，旨在解决“颜色管理职责界限模糊”的设计问题，并建立一套精准、可控的**选择性主题注入（Selective Theming）**策略。

## 1. 核心问题研判

目前在 `kit` 命名空间下的 UI 组件跳过了构造函数的显式注入，直接依赖 `Theme.of(context).extension<AppTheme>()` 进行内部状态提取（服务定位器模式）。这在极简的同时带来了严重的副作用：

- **反模式隐患**：底层原子组件过度依赖外层路由上下文。
- **上下文逃逸**：当组件置于 Overlay、Dialog 或特殊浮层中时，会因节点树断层丢失 `AppTheme`，导致 UI 崩溃或全黑。
- **高重绘开销与泛滥**：所有组件（包括大面积静态背景板）都被迫卷走主题渲染链路，影响性能及视觉克制。

## 2. 核心架构逻辑：选择性主题注入 (Selective Theming)

为了保持代码的低冗余且解决缺陷，采用**“主视觉动态化 + 骨架基建静态化”**的二元策略。

### 2.1 主视觉锚点动态化 (Dynamic Visual Anchors)

**ONLY** 决定页面业务/游戏属性的关键交互元素与视觉高光，允许通过 `ThemeExtension` 汲取主题色彩。
具体哪个组件（按钮、文字、指示器）读取哪种主题色（`medium`、`light` 等），由开发者在构建装配层时根据具体视觉需求主动决定，不在此设定强制的刚性映射契约。

### 2.2 骨架基建静态化 (Static Skeleton Infrastructure)

凡不构成强主题特征的“结构支撑”元素，必须彻底剥离 `ThemeExtension` 依赖。

- **纯容器与文字元素**：如各种底座页面、`Card` 背景、分割线、以及无警示意义的常规文字。
- **强制规程**：上述元素 **ONLY** 允许退回引用 `constants/colors.dart` 中定义的常量色（例如 `UiColors.white` 或 `UiColors.grey800`）。**REJECT** 在这类组件中调用 `AppTheme` 甚至试图将其与黑色等静态色进行混合生成。

## 3. 重构执行计划与柔性 DI (Flexible DI Integration)

对于需要支持主题色的底层组件（例如 `ConfirmButton`），不可强行废除上下文检索（这将导致大量且令人痛苦的手工传参工作），而是采用“柔性 DI (可选式依赖注入)”模型。

### 3.1 预设重写插槽

在底层组件的构造函数中，暴露开放外部传入颜色的参数。

```dart
final Color? customHighlightColor;
// 或者对于文字
final Color? customTextColor;
```

### 3.2 优先级决策模型

组件的 `build` 函数内部提取颜色时，必须遵循以下不可侵犯的优先级链路：

```dart
// 1. 获取当前节点树的皮肤
final AppTheme? currentTheme = Theme.of(context).extension<AppTheme>();

// 2. 决策链路：显式属性劫持 > 上下文解析 > 静态兜底锁
final Color finalPrimaryColor = widget.customHighlightColor
    ?? currentTheme?.medium
    ?? UiColors.grey500;
```

### 3.3 测试与界线锁死

在完成这些重构后，这部分代码应当能在无 `AppTheme` 顶层包裹的测试环境中健康生存：

- 在隔离态渲染时，它能够凭借上述链条自动退化至安全的常量灰色。
- 在 `ScoreSyncPage` 或 `SettingsPage` 等“组装厂”代码里，装配代码 ONLY 在需要覆盖预设皮肤色（比如一个破坏类的红色警告按钮）时，才会主动启用并传入 `customHighlightColor`。

## 4. 动态主题色注入受控清单

基于历次重构演进与色彩隔离要求，以下组件及业务场景属于主视觉动态化管辖，为合法的颜色提取端：

### 4.1 UI 基础交互与排印 (原子/分子级)

- 核心功能按钮 (如 ConfirmButton)：汲取 basic色。同时遵守柔性 DI 保持 customHighlightColor 开放重写。
- 分页控制指示点：汲取 basic色。
- 标签分类激活文字：汲取 basic色。
- 辅层轻量高光文本：汲取 light
- 弹窗及强反差承载文本：汲取 dark色。典型为 MusicData 内深白底弹框的正文，MUST 被封顶于 #2D2D2D 的暗色极值之下。

### 4.2 业务容器与面板基建 (区块级)

- 边栏面板底区：汲取 medium色作视觉锚定。
- Logo 水印与大修饰层：汲取 light色，配合透明通道构筑。
- SkinColorPanel 面板系统：包含内部 HSL 调节控件、矩形目标取色选择器。MUST 严格绑定当前处于变更管线的 AppTheme 实例。
- \_MiniPreview：模拟高保真沙盒预览，MUST 读取宿主传入的子集主题色彩而非当前全局应用主题。

### 4.3 顶层业务装配 (页面级)

- ScoreSyncPage：顶层背景及主路由脚手架 MUST 解析由 GameProvider 提供的主题派发体系，废止硬编码。
- MusicDataPage：顶端背景层接轨动态 AppTheme，配合列表项内部的差异化渲染。
- PersonalizationPage：主题列表选单、下辖的所有选项卡容器，MUST 实时同步响应环境重绘与主题切换帧。

### 4.4 禁制注入清单 (静态锁死特区)

为遵守 §2.2 骨架基建静态化，以下区域 REJECT 任何 Theme 颜色探测，MUST 采用 UiColors 常量池进行硬编码静态着色：

- PageShell 容器体系：内部的全局半透明 Glass 层、模糊过渡罩。
- 所有设置页面 (Settings)：除 SkinColorPanel 等强域属区块外的底座、全量列表背景。
- 数据卡片体系：任何承担基础信息展示任务的白色白板、容器 Card 底色区块。
