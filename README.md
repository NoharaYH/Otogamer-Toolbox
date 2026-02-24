# Otogamer-Toolbox (音游工具箱)

一款高颜值的 Maimai & Chunithm 游戏工具箱。
基于 Flutter 开发，主打流畅的物理动画，提供查分、推分及数据迁移等功能。

---

## 🏗 Architecture Tree (架构树)

本项目严格遵循分层架构设计。所有贡献代码必须严格归属于以下结构层级：

```plaintext
lib/
├── main.dart                  # 应用入口
├── kernel/                    # 基础设施层 (Infrastructure Layer)
│   ├── di/                    # 依赖注入 (Dependency Injection)
│   ├── services/              # 系统服务 (Storage, System Utils)
│   └── state/                 # 全局运行状态 (Global App State)
│
├── network/                   # 通信中心 (Networking Layer)
│   ├── mai_api/               # Maimai 专用通信模块 (API Clients)
│   └── chu_api/               # Chunithm 专用通信模块 (Placeholder)
│
├── logic/                     # 业务处理中枢 (Domain Logic Layer)
│   ├── mai_music_data/        # Maimai 垂直业务包
│   │   ├── data_formats/      # 数据格式标准 (Xray Schemas)
│   │   ├── transform/         # 变形/精炼引擎 (Refinery)
│   │   ├── data_sync/         # 同步调度器 (Synchronizer)
│   │   └── library/           # 核心曲库/数据中心 (Vault)
│   │
│   └── chu_music_data/        # Chunithm 垂直业务包
│       ├── data_formats/      # (Placeholder)
│       └── ...                # 结构同上
│
└── ui/                        # 表现层 (Presentation Layer)
    ├── design_system/         # 原子级设计系统 (Atomic Design Kit)
    └── pages/                 # 业务功能页面 (Feature Assembly)
```

> **注意**: 旧版文件夹 (`lib/views/`, `lib/widgets/`) 已被废弃。**严禁**向其中添加新代码，请优先使用上述新架构。

---

## 🛠 Tech Stack (技术栈)

- **核心框架**: Flutter (Dart 3.x)
- **状态管理**: `provider`
- **网络请求**: `dio`
- **依赖注入**: `get_it`, `injectable`
- **UI 哲学**: 自定义组件系统，纯代码实现高性能动画 (Pure Programmatic Animations)。

## 🚀 Getting Started (快速开始)

1.  **环境准备**:
    - Flutter SDK (Stable Channel, 最新版)
    - Visual Studio Code (推荐编辑器)

2.  **安装依赖**:

    ```bash
    flutter pub get
    flutter run
    ```

3.  **代码风格**:
    - 遵循标准 Dart lints 规范。
    - 优先考虑代码的可读性和模块化。

---
