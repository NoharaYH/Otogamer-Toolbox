# UI 架构文档

## 目录结构

```
lib/ui/
│
├── design_system/                          # 设计系统（原材料与动效引擎）
│   │
│   ├── page_shell.dart                     # 基础容器：毛玻璃底板容器
│   │
│   ├── constants/                          # 原子常量定义
│   │   ├── sizes.dart                      # 间距、圆角、动画时长、自适应边距计算
│   │   └── assets.dart                     # 资源路径映射 (背景、Logo、难度图)
│   │
│   ├── kit_shared/                         # 通用原子与协议
│   │   ├── game_page_item.dart             # ✅ 协议：多游戏轮播页面定义
│   │   ├── kit_game_carousel.dart          # ✅ 引擎：统一动效轮播器 (视差/挤压/背景渐变)
│   │   ├── sticky_dot_indicator.dart       # 组件：粘性动力学分页指示器
│   │   └── confirm_button.dart             # 组件：统一缩放反馈确认按钮
│   │
│   ├── kit_score_sync/                     # 业务组件：成绩同步专项
│   │   ├── score_sync_card.dart            # 容器：支持弹性滚动的业务卡片
│   │   ├── score_sync_form.dart            # 复合：多模式 Token 输入与验证表单
│   │   ├── sync_log_panel.dart             # 复合：阶段化时序日志控制台
│   │   └── mai_dif_choice.dart             # 业务：舞萌/中二难度选择器
│   │
│   └── visual_skins/                       # 皮肤系统 (ThemeExtension 伪 DI)
│       ├── skin_extension.dart             # 接口：定义 primary/success/error 及背景渲染
│       └── implementations/                # 实现：各游戏具体视觉调性定义 (Maimai/Chunithm)
│
└── pages/                                  # 组装层
    │
    ├── score_sync/                         # 传分模块
    │   ├── score_sync_page.dart            # 组装：通过 Carousel 协议挂载各游戏页
    │   └── components/                     # 局部逻辑：Logo 包装器与业务流水线
    │
    └── settings/                           # 设置模块
        └── settings_page.dart              # 组装：基础表单页面
```

---

## 核心设计原则

### 1. 协议驱动 UI (Protocol-Driven UI)

- **KitGameCarousel**：将物理层动画（视差、缩放、旋转、渐变）与业务层内容完全解耦。
- **扩展性**：新增游戏功能 ONLY 需要向该协议注册一个新的 `GamePageItem`，无需修改任何动效代码。

### 2. 皮肤依赖注入 (ThemeExtension DI)

- **去硬编码**：严禁在 `kit` 层使用 `Colors.xxx` 或硬编码 Hex。
- **强制约束**：组件必须通过 `Theme.of(context).extension<SkinExtension>()` 消费颜色。
- **自动插值**：利用 `SkinExtension.lerp` 方法，背景与 UI 色彩随滑动进度自动完成平滑过渡。

### 3. 单向依赖方向

- **Pages** -> **Application** -> **Kit (Shared/Specific)** -> **Visual Skins**
- **Logic** <- **Application** -> **Kernel**
- **REJECT**：严禁 Page 层直接引用具体的皮肤实现类 (Implementations)，应通过 `GamePageItem` 协议层注入。
- **REJECT**：严禁 Logic 层引用 Flutter/UI 相关的类 (如 TextEditingController)，此类需求应在 Application 层处理。

---

## 动效引擎协议 (KitGameCarousel)

### GamePageItem 定义

用于描述参与轮播的每一个单元：

```dart
class GamePageItem {
  final SkinExtension skin;    // 该页面的皮肤实现
  final Widget content;        // 该页面的业务内容
  final String title;          // 标识符
}
```

### 渲染流程

1. **背景层**：根据当前 `pageIndex` 和 `nextIndex` 自动执行 `Opacity` 叠加，实现跨背景渐变。
2. **内容层**：基于 `abs(page - index)` 计算缩放比例 (Scale) 与视差偏移 (Parallax Offset)，产生物理挤压感。
3. **指示器层**：计算两页之间的 `lerp(skinA, skinB, t)`，驱动指示器颜色平滑流变。

---

## 颜色管理规范 (Semantic Tokens)

### 1. 核心调色盘

每个皮肤必须提供以下语义化 Token：

- **light**：用于浅层叠加或渐变起始。
- **medium**：主色调，用于按钮、高亮指示。
- **dark**：深色调，用于边框、投影或渐变终止。

### 2. 交互状态

- **Disabled**：应通过 `medium.withOpacity(0.4)` 或专门的 `inactiveToken` 派生，禁止使用 Material 默认灰。
- **Feedback**：点击变暗效果应由 `lerp(baseColor, Colors.black, factor)` 生成，确保色相调性一致。

---

## 开发约束

- **命名规范**：所有设计系统组件必须以 `Kit` 或该业务包的前缀命名。
- **逻辑隔离**：`kit` 层组件不得持有 `Provider` 业务状态，只接受原始数据与回调。
- **自适应**：所有垂直边距必须通过 `UiSizes.getTopMarginWithSafeArea` 动态获取，以兼容不同规格的 Notch/Dynamic Island。
- **统一交互组件**：所有类似确认、取消等基础交互按钮组件，必须统一从 `kit_shared/confirm_button.dart` 等原子路径引入，**REJECT** 在业务包内散装实现 `GestureDetector` + `Container` 容器。
- **全局物理反馈**：所有自定义可点击交互组件 (如圆圈、纯图按钮的缩放反馈)，必须遵循“按下即时收缩、松开即时回正”的物理反馈。此动效 **ONLY** 允许通过包裹 `kit_shared/kit_bounce_scaler.dart` 实现包装。**REJECT** 各业务线独立实现 `ScaleTransition` 或手势识别逻辑。
- **层级动效规律**：所有涉及到层级交替（展现与销毁）的滑入滑出或淡入淡出动效，必须从 `kit_shared/kit_animation_engine.dart` 摄取标准的曲线与时长（如展出使用 600ms `easeOutQuart`），**REJECT** 使用魔数硬编码的 Curve。
- **层级动效约束**：所有涉及到层级交替的淡入淡出效果，**必须 ONLY** 在透明度 (Opacity) 层面进行调整。**REJECT** 因高度、边距变化或动态大小 (`AnimatedSize`、`AnimatedCrossFade` 挤压等) 引起的 DOM 结构与物理容器体积跳变。

---

**文档版本**: v2.0 (Protocol Update)  
**最后更新**: 2026-02-24  
**维护者**: Antigravity Assistant Team
