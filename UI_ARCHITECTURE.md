# UI 架构文档

## 目录结构

```
lib/ui/
│
├── design_system/                          # 设计系统（原材料仓库）
│   │
│   ├── page_shell.dart                     # 页面外壳
│   │   # 背景 + 白色毛玻璃底板 + 头部区域（Logo + 滑动圆点）
│   │   # 非强制：设置页和传分WebView页不使用
│   │
│   ├── constants/                          # 固定数值（死数据）
│   │   ├── sizes.dart                      # 间距16、圆角20、按钮圆角12、动画时长300ms/200ms、输入框高44
│   │   └── assets.dart                     # 所有图片路径（舞萌背景×8 + 中二背景×4 + Logo×2 + 难度图×6）
│   │
│   ├── kit_shared/                         # 共享组件（多页共用）
│   │   ├── sticky_dot_indicator.dart       # 滑动指示器圆点（粘性拉伸动画）
│   │   ├── toast_card.dart                 # Toast 提示条外观（图标+文字胶囊条）
│   │   └── toast_queue_manager.dart        # Toast 排队管理（进场/堆叠/退场动画）
│   │
│   ├── kit_score_sync/                     # 成绩同步组件（传分专属）
│   │   ├── mode_tabs.dart                  # ✅ 可复用：模式切换按钮（水鱼/双平台/落雪）
│   │   ├── token_input.dart                # ✅ 可复用：Token 输入框（粘贴/显示隐藏/验证）
│   │   ├── content_animator.dart           # ✅ 可复用：内容淡入淡出切换器
│   │   └── game_specific_content.dart      # ❌ 不可复用：游戏专属内容
│   │       ├── MaimaiDifficultySelector    #   - 舞萌：6难度多选 + 开始导入按钮
│   │       └── ChunithmDifficultySelector  #   - 中二：难度选择（待开发）
│   │
│   └── visual_skins/                       # 皮肤系统（ThemeExtension 伪DI 核心）
│       ├── skin_extension.dart             # 接口定义：亮/中/暗 三色 + 背景渲染方法
│       ├── manager.dart                    # 运行时皮肤切换控制台
│       └── implementations/                # 具体皮肤包
│           ├── maimai_dx/
│           │   └── circle_background.dart  # 舞萌皮肤：粉色渐变 + 旋转圆环 + 三色定义
│           └── chunithm/
│               └── verse_background.dart   # 中二皮肤：蓝底 + 城市画面 + 三色定义
│
└── pages/                                  # 组装车间（只拼装，不造零件）
    │
    ├── home/                               # 主页（套 page_shell）
    │   ├── home_page.dart                  # 主页布局：滑动分页 + 背景切换
    │   └── components/
    │       ├── maimai_content.dart         # 舞萌页：组装组件 + 注入粉色皮肤
    │       └── chunithm_content.dart       # 中二页：组装组件 + 注入金色皮肤
    │
    ├── transfer/
    │   └── transfer_web_page.dart          # 传分授权WebView（不套shell，全屏）
    │
    ├── settings/
    │   └── settings_page.dart              # 设置页（不套shell，简单表单）
    │
    └── side_panel/                         # 侧方弹出面板（未来，套shell）
        └── side_panel_page.dart
```

---

## 核心设计原则

### 1. 设计系统与页面分离

- **design_system/**：存放所有 UI 组件，按功能分文件夹
- **pages/**：只负责组装组件，决定布局和绑定业务数据
- **依赖方向**：`pages/` → `design_system/`（单向依赖）

### 2. 组件无业务逻辑

- 组件本身不含业务逻辑
- 颜色通过 `ThemeExtension` 动态获取，不写死游戏专属颜色
- 只负责外观和交互，不决定数据来源

### 3. 命名规范

- **组件包**：`kit_` 前缀（如 `kit_shared/`, `kit_score_sync/`）
- **配置类**：无前缀（如 `constants/`, `visual_skins/`）
- **单文件**：无前缀（如 `page_shell.dart`）

---

## ThemeExtension 伪依赖注入系统

### 核心概念

**ThemeExtension 伪DI** 是一种利用 Flutter 原生 `ThemeExtension` 机制实现的颜色依赖注入方案。

**核心思想**：

- 组件只知道"我要用主色调"，不知道当前是"舞萌粉"还是"中二金"
- 切换背景 = 切换整套配色，所有引用主题色的组件自动变色

---

### 1. 皮肤接口定义

**文件位置**：`design_system/visual_skins/skin_extension.dart`

```dart
import 'package:flutter/material.dart';

/// 皮肤扩展接口
/// 每个具体的皮肤实现此接口，提供主题色和渲染逻辑
abstract class SkinExtension extends ThemeExtension<SkinExtension> {
  /// 亮色调 - 用于背景渐变、玻璃效果叠加层
  Color get light;

  /// 中性色调 - 用于主要 UI 元素（卡片、按钮激活态）
  Color get medium;

  /// 暗色调 - 用于边框、阴影、分割线
  Color get dark;

  /// 渲染背景 Widget
  Widget buildBackground(BuildContext context);

  @override
  SkinExtension copyWith({Color? light, Color? medium, Color? dark});

  @override
  SkinExtension lerp(ThemeExtension<SkinExtension>? other, double t);
}
```

---

### 2. 具体皮肤实现

#### 舞萌皮肤

**文件位置**：`design_system/visual_skins/implementations/maimai_dx/circle_background.dart`

```dart
import 'package:flutter/material.dart';
import '../../skin_extension.dart';
import '../../../constants/assets.dart';

/// 舞萌 DX - Circle 主题皮肤
class MaimaiSkin extends SkinExtension {
  const MaimaiSkin();

  // ==================== 主题色定义 ====================

  @override
  Color get light => /* 浅粉色 - 用于背景渐变起始 */;

  @override
  Color get medium => /* 主粉色 - 用于按钮激活态、主要UI元素 */;

  @override
  Color get dark => /* 深粉色 - 用于渐变终点、边框、阴影 */;

  // ==================== 背景渲染 ====================

  @override
  Widget buildBackground(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 渐变底色
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [light, dark],
            ),
          ),
        ),
        // 旋转图案
        _RotatingImage(
          assetPath: AppAssets.maimaiBgPattern,
          duration: const Duration(seconds: 240),
          scale: 3.5,
        ),
        _RotatingImage(
          assetPath: AppAssets.maimaiCircleWhite,
          duration: const Duration(seconds: 180),
          scale: 1.4,
          reverse: true,
        ),
        // ... 其他旋转圆环和四角装饰
      ],
    );
  }

  // ==================== ThemeExtension 必需方法 ====================

  @override
  SkinExtension copyWith({Color? light, Color? medium, Color? dark}) {
    return const MaimaiSkin(); // 皮肤是常量，不需要复制
  }

  @override
  SkinExtension lerp(ThemeExtension<SkinExtension>? other, double t) {
    if (other is! MaimaiSkin) return this;
    return this; // 简化实现，不做插值
  }
}

// 旋转图片组件（内部实现）
class _RotatingImage extends StatefulWidget {
  final String assetPath;
  final Duration duration;
  final double scale;
  final bool reverse;

  const _RotatingImage({
    required this.assetPath,
    required this.duration,
    this.scale = 1.0,
    this.reverse = false,
  });

  @override
  State<_RotatingImage> createState() => _RotatingImageState();
}

class _RotatingImageState extends State<_RotatingImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double angle = _controller.value * 2 * 3.14159;
            return Transform.rotate(
              angle: widget.reverse ? -angle : angle,
              child: Transform.scale(scale: widget.scale, child: child!),
            );
          },
          child: Image.asset(widget.assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
```

#### 中二皮肤

**文件位置**：`design_system/visual_skins/implementations/chunithm/verse_background.dart`

```dart
import 'package:flutter/material.dart';
import '../../skin_extension.dart';
import '../../../constants/assets.dart';

/// 中二节奏 - Verse Town 主题皮肤
class ChunithmSkin extends SkinExtension {
  const ChunithmSkin();

  // ==================== 主题色定义 ====================

  @override
  Color get light => /* 浅蓝色 - 用于背景渐变起始 */;

  @override
  Color get medium => /* 金黄色 - 用于按钮激活态、主要UI元素 */;

  @override
  Color get dark => /* 深蓝色 - 用于边框、阴影 */;

  // ==================== 背景渲染 ====================

  @override
  Widget buildBackground(BuildContext context) {
    const double designWidth = 393.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double scale = constraints.maxWidth / designWidth;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Image.asset(AppAssets.chunithmBg, fit: BoxFit.cover),
            ),
            Positioned(
              left: -515 * scale,
              bottom: 0,
              width: 1500 * scale,
              height: 733 * scale,
              child: Image.asset(
                AppAssets.chunithmVerseTown,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
            // ... 角落装饰
          ],
        );
      },
    );
  }

  // ==================== ThemeExtension 必需方法 ====================

  @override
  SkinExtension copyWith({Color? light, Color? medium, Color? dark}) {
    return const ChunithmSkin();
  }

  @override
  SkinExtension lerp(ThemeExtension<SkinExtension>? other, double t) {
    if (other is! ChunithmSkin) return this;
    return this;
  }
}
```

---

### 3. 组件中获取颜色

#### 示例：模式切换按钮

**文件位置**：`design_system/kit_score_sync/mode_tabs.dart`

```dart
import 'package:flutter/material.dart';
import '../visual_skins/skin_extension.dart';

class ModeTabs extends StatelessWidget {
  final int selectedMode; // 0: 水鱼, 1: 双平台, 2: 落雪
  final ValueChanged<int> onModeChanged;

  const ModeTabs({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 通过 ThemeExtension 获取当前皮肤
    final skin = Theme.of(context).extension<SkinExtension>();

    // ✅ 如果没有皮肤，使用默认值（防御性编程）
    final activeColor = skin?.medium ?? Colors.pink;
    final lightColor = skin?.light ?? Colors.pink.shade100;

    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTab(0, '水鱼', activeColor),
          _buildTab(1, '双平台', activeColor),
          _buildTab(2, '落雪', activeColor),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String text, Color activeColor) {
    final isSelected = selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? activeColor : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

### 4. 页面中注入皮肤

#### 示例：舞萌页面

**文件位置**：`pages/home/components/maimai_content.dart`

```dart
import 'package:flutter/material.dart';
import '../../../design_system/visual_skins/implementations/maimai_dx/circle_background.dart';
import '../../../design_system/kit_score_sync/mode_tabs.dart';
import '../../../design_system/kit_score_sync/token_input.dart';

class MaimaiContent extends StatefulWidget {
  const MaimaiContent({super.key});

  @override
  State<MaimaiContent> createState() => _MaimaiContentState();
}

class _MaimaiContentState extends State<MaimaiContent> {
  int _selectedMode = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ 通过 Theme.copyWith 注入舞萌皮肤
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [const MaimaiSkin()], // 注入舞萌皮肤
      ),
      child: Column(
        children: [
          // Logo 区域
          Image.asset('assets/logo/maimai.png', height: 80),

          const SizedBox(height: 30),

          // ✅ ModeTabs 自动使用舞萌粉色
          ModeTabs(
            selectedMode: _selectedMode,
            onModeChanged: (mode) => setState(() => _selectedMode = mode),
          ),

          const SizedBox(height: 16),

          // ✅ TokenInput 自动使用舞萌粉色
          const TokenInput(
            hint: '请输入水鱼成绩导入Token',
          ),
        ],
      ),
    );
  }
}
```

#### 示例：中二页面

**文件位置**：`pages/home/components/chunithm_content.dart`

```dart
import 'package:flutter/material.dart';
import '../../../design_system/visual_skins/implementations/chunithm/verse_background.dart';
import '../../../design_system/kit_score_sync/mode_tabs.dart';
import '../../../design_system/kit_score_sync/token_input.dart';

class ChunithmContent extends StatefulWidget {
  const ChunithmContent({super.key});

  @override
  State<ChunithmContent> createState() => _ChunithmContentState();
}

class _ChunithmContentState extends State<ChunithmContent> {
  int _selectedMode = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ 通过 Theme.copyWith 注入中二皮肤
    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [const ChunithmSkin()], // 注入中二皮肤
      ),
      child: Column(
        children: [
          // Logo 区域
          Image.asset('assets/logo/chunithm.png', height: 80),

          const SizedBox(height: 30),

          // ✅ 同一个 ModeTabs，自动使用中二金色
          ModeTabs(
            selectedMode: _selectedMode,
            onModeChanged: (mode) => setState(() => _selectedMode = mode),
          ),

          const SizedBox(height: 16),

          // ✅ 同一个 TokenInput，自动使用中二金色
          const TokenInput(
            hint: '请输入水鱼成绩导入Token',
          ),
        ],
      ),
    );
  }
}
```

---

### 5. 背景渲染

#### 在 page_shell 中渲染背景

**文件位置**：`design_system/page_shell.dart`

```dart
import 'package:flutter/material.dart';
import 'visual_skins/skin_extension.dart';

class PageShell extends StatelessWidget {
  final Widget child;

  const PageShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // ✅ 获取当前皮肤
    final skin = Theme.of(context).extension<SkinExtension>();

    return Stack(
      children: [
        // 1. 背景层（从皮肤系统取）
        if (skin != null)
          Positioned.fill(
            child: skin.buildBackground(context),
          ),

        // 2. 毛玻璃底板
        Positioned(
          top: MediaQuery.of(context).size.height * 0.05,
          left: MediaQuery.of(context).size.width * 0.05,
          right: MediaQuery.of(context).size.width * 0.05,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(color: Colors.white.withOpacity(0.8)),
            ),
          ),
        ),

        // 3. 内容区
        Positioned.fill(child: child),
      ],
    );
  }
}
```

---

## 可扩展点

### 1. 新增游戏皮肤

**步骤**：

1. 在 `visual_skins/implementations/` 下创建新文件夹（如 `ongeki/`）
2. 创建皮肤实现类（如 `ongeki_background.dart`）
3. 实现 `SkinExtension` 接口，定义三色 + 背景渲染
4. 在页面中通过 `Theme.copyWith(extensions: [OngekiSkin()])` 注入

**示例**：

```
visual_skins/implementations/
├── maimai_dx/
├── chunithm/
└── ongeki/                          # ✅ 新增：音击皮肤
    └── ongeki_background.dart       # 实现 SkinExtension
```

---

### 2. 新增功能组件包

**步骤**：

1. 在 `design_system/` 下创建新文件夹，使用 `kit_` 前缀
2. 将可复用组件单独成文件
3. 将不可复用组件放在 `game_specific_content.dart` 内
4. 组件通过 `Theme.of(context).extension<SkinExtension>()` 获取颜色

**示例**：

```
design_system/
├── kit_shared/
├── kit_score_sync/
└── kit_achievements/                # ✅ 新增：成就系统组件包
    ├── achievement_card.dart        # 可复用：成就卡片
    ├── progress_bar.dart            # 可复用：进度条
    └── game_specific_content.dart   # 不可复用：游戏专属成就展示
```

---

### 3. 新增页面

**步骤**：

1. 在 `pages/` 下创建新文件夹
2. 决定是否使用 `page_shell`
3. 在页面中通过 `Theme.copyWith` 注入对应皮肤
4. 组装 `design_system/` 中的组件

**示例**：

```
pages/
├── home/
├── transfer/
├── settings/
└── leaderboard/                     # ✅ 新增：排行榜页面
    ├── leaderboard_page.dart        # 主页面（套 page_shell）
    └── components/
        ├── maimai_leaderboard.dart  # 舞萌排行榜（注入 MaimaiSkin）
        └── chunithm_leaderboard.dart # 中二排行榜（注入 ChunithmSkin）
```

---

## 依赖方向规则

### ✅ 允许的依赖

```
pages/ → design_system/                    # 页面引用组件
design_system/kit_xxx/ → visual_skins/     # 组件获取皮肤
design_system/kit_xxx/ → constants/        # 组件使用常量
design_system/page_shell → kit_shared/     # page_shell 使用共享组件
```

### ❌ 禁止的依赖

```
design_system/ → pages/                    # 组件不能引用页面
pages/ → visual_skins/implementations/     # 页面不能直接引用具体皮肤实现
kit_xxx/ → kit_yyy/                        # 组件包之间不能互相引用（除非通过 kit_shared）
```

### 🔧 正确的引用方式

```dart
// ❌ 错误：页面直接引用具体皮肤实现
import '../../../design_system/visual_skins/implementations/maimai_dx/circle_background.dart';

// ✅ 正确：通过 Theme.copyWith 注入
Theme(
  data: Theme.of(context).copyWith(
    extensions: [const MaimaiSkin()],
  ),
  child: MyWidget(),
)

// ❌ 错误：组件直接使用写死的颜色
Container(color: Color(0xFFFF83AA))

// ✅ 正确：组件通过 SkinExtension 获取颜色
final skin = Theme.of(context).extension<SkinExtension>();
Container(color: skin?.medium ?? Colors.pink)
```

---

## 背景主题颜色管理

### 颜色定义

每个皮肤实现必须提供**至少三个主题色**（`light`、`medium`、`dark`），未来可根据需要添加更多颜色。

```
visual_skins/implementations/
├── maimai_dx/circle_background.dart
│   ├── light    # 浅色系
│   ├── medium   # 中性色系
│   └── dark     # 深色系
│
└── chunithm/verse_background.dart
    ├── light    # 浅色系
    ├── medium   # 中性色系
    └── dark     # 深色系
```

**注意**：具体颜色值在各皮肤实现中定义，可随时调整。未来可能会添加新的颜色类型（如 `accent`、`surface` 等）。

### 如何引用颜色

```dart
// 在组件中获取当前皮肤
final skin = Theme.of(context).extension<SkinExtension>();

// 使用颜色（如果皮肤不存在，使用默认值）
Container(
  color: skin?.medium ?? Colors.pink,        // 使用中性色
  child: Text(
    'Hello',
    style: TextStyle(color: skin?.dark),     // 使用深色
  ),
)

// 渐变示例
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        skin?.light ?? Colors.white,
        skin?.dark ?? Colors.grey,
      ],
    ),
  ),
)
```

---

## 常见问题

### Q1: 为什么组件要通过 ThemeExtension 获取颜色，而不是直接传参？

**A**:

- **解耦**：组件不需要知道具体颜色值，只需要知道"我要主色调"
- **复用**：同一个组件可以在不同游戏下自动变色
- **维护**：修改颜色只需要改皮肤实现，不需要改组件代码

### Q2: 什么时候应该创建新的 `kit_xxx/` 文件夹？

**A**:

- 当有一组功能相关的组件需要组织在一起时
- 当这些组件可能被多个页面复用时
- 当这些组件有明确的业务边界时（如成绩同步、用户资料、成就系统）

### Q3: 游戏专属组件应该放在哪里？

**A**:

- 如果是**外观相同、只是颜色不同**的组件 → 放在 `kit_xxx/` 下，通过 ThemeExtension 自动变色
- 如果是**外观完全不同**的组件 → 放在 `kit_xxx/game_specific_content.dart` 内

### Q4: page_shell 是强制使用的吗？

**A**:

- **不强制**
- **使用场景**：需要统一背景 + 毛玻璃底板 + 头部区域的页面（如主页）
- **不使用场景**：设置页、WebView 页等特殊页面

---

## 总结

### 核心优势

1. **组件复用**：同一个组件在不同游戏下自动变色
2. **易于扩展**：新增游戏只需添加皮肤实现，无需修改组件
3. **职责清晰**：设计系统负责外观，页面负责组装
4. **维护简单**：颜色集中管理，修改皮肤不影响组件

### 关键约束

1. **严禁写死颜色**：组件必须通过 `SkinExtension` 获取颜色
2. **单向依赖**：`pages/` → `design_system/`，不能反向
3. **命名规范**：组件包使用 `kit_` 前缀
4. **皮肤实现**：每个皮肤必须提供 `light/medium/dark` 三色 + 背景渲染

---

**文档版本**: v1.0  
**最后更新**: 2026-02-10  
**维护者**: Otogamer-Toolbox Team
