# OTOKiT (音游工具箱)

一款高颜值的 Maimai & Chunithm 游戏工具箱。
基于 Flutter 开发，主打流畅的物理动画，提供查分、推分及数据迁移等功能。

---

## 🏗 Architecture Tree (架构树)

本项目严格遵循分层架构设计。所有贡献代码必须严格归属于以下结构层级：

```plaintext
lib/
├── main.dart                  # 应用入口
├── kernel/                    # 基础内核层 (Infrastructure Layer)
│   ├── di/                    # 依赖注入配置 (Injection Config)
│   └── services/              # 系统级服务 (Storage, System API)
│
├── application/               # 应用状态层 (Application Layer / Mediators)
│   ├── mai/                   # Maimai UI 状态中转
│   ├── chu/                   # Chunithm UI 状态中转
│   ├── transfer/              # 传分业务状态中转
│   └── shared/                # 全局通用 UI 状态 (Toast, Global Navigation)
│
├── network/                   # 通信中心 (Networking Layer)
│   ├── mai_api/               # Maimai 专用通信模块 (API Clients)
│   └── chu_api/               # Chunithm 专用通信模块 (Placeholder)
│
├── logic/                     # 业务处理中枢 (Domain Logic Layer - Pure Dart)
│   ├── mai_music_data/        # Maimai 垂直业务逻辑包
│   │   ├── data_formats/      # 数据格式定义
│   │   ├── transform/         # 数据洗炼引擎
│   │   ├── data_sync/         # 同步调度逻辑
│   │   └── library/           # 核心曲库管理
│   │
│   └── chu_music_data/        # Chunithm 垂直业务逻辑包
│       └── ...                # 结构同上
│
└── ui/                        # 表现层 (Presentation Layer)
    ├── theme/                 # 原子级设计系统 (Kit & Skins)
    └── pages/                 # 业务功能页面组装 (Assembly)
```

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
