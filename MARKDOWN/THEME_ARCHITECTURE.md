# 视觉皮肤与主题架构规程 (Theme Architecture)

## 0. 设计理念：选择性主题注入

- 动态主视觉锚点：ONLY 页面业务交互组件、视觉高光点准许依附 ThemeExtension 获取色调。
- 静态骨架隔离：基础容器、全量设置底板、说明性文字 MUST 依赖降级至静态灰白池。REJECT 向外检索 AppTheme 并混色。
- 柔性依赖注入：底层原子支持 customHighlightColor 插槽重写。降级决策链：入参重写 > 上下文汲取 > 纯色兜底锁。

## 1. 核心约束：三色与状态隔离

- 色盘契约：
  - light：水印辅助层、次级高光轻量文本。
  - basic：控制组件、进度指引、边缘标签激活主段落。
  - dark：深色承压文本与极限投影。极值上限强锁 #2D2D2D 屏障。
- 数据流向：JSON 动态配置覆盖级 > Dart 原生工厂设定优先级。
- 隔离动作反馈：Disabled 组件失效态 ONLY 采用纯黑遮罩器叠加致暗。REJECT 使用或剥离出独立灰化参数。

## 2. 自动化建构 (AST Pipeline Registry)

- 提取信标：皮肤对象文件 MUST 装饰于 @GameTheme() 注解被生成器捕获搜集。
- 管道封箱：依靠 build_runner 实施 AST 片段分析，自动归结 domain 类族群并组装 theme_catalog.g.dart 只读表册。
- 零侵入对接：展示与装配页 MUST ONLY 订阅上层流出的静态表数据，REJECT 工程端发生手动类注册增删。

## 3. 颜色注入控制名单

- 合法探测特区：
  - 核心操作项 ConfirmButton 机制、StickyDotIndicator 指示阵列。
  - 路由容器 ScoreSyncPage 主结构、业务顶层包装罩。
  - SkinColorPanel 主题微调池 (仅限当前调制句柄对象探测)。
- 严禁挂载禁区：
  - PageShell 全局遮控与毛玻璃底层。
  - 数据 Card 与承压白板结构图。
  - Settings 无关设置子层静态盘。

## 4. 主题列表

### 全局主题

- 暗色星轨✅️

### 舞萌主题

- Circle✅️
- Prism Plus
- Prism
- Buddies Plus
- Buddies
- Festival Plus
- Festival
- Universe
- Splash Plus
- Splash
- DX

### 中二主题

- Verse✅️
- Luminous Plus
- Sun Plus
- Sun
- New
