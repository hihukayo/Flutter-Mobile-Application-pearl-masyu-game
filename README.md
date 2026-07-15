# 🧩 数独 Sudoku

Flutter 数独移动应用，支持用户登录注册、多种难度随机数独游戏、个人中心等功能。

## ✨ 功能

- **用户系统**：注册 / 登录（后端 MySQL 存储，密码 SHA256 加密）
- **数独游戏**：
  - 3×3 经典九宫格 & 4×4 十六进制数独
  - **难度自动随机**：极简 / 困难 / 中等 / 简单，遵循正态分布，避免连续重复
  - 计时器、暂停 / 继续
  - 笔记模式（候选数字标记）
  - 撤销 / 重做（支持笔记操作）
  - 错误计数（3×3 限 3 次，4×4 限 6 次）
  - 自动求解、重置
  - 触感反馈
- **排行榜**：按分数排名
- **个人中心**：修改用户名 / 密码 / 手机号、注销账号、头像

## 🛠 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Flutter (Dart) |
| 后端 | Dart shelf + shelf_router |
| 数据库 | MySQL |
| 字体 | Google Fonts (Montserrat) |

---

## 🚀 快速开始

### 1. 环境要求

| 工具 | 版本要求 |
|------|---------|
| Flutter | ^3.12 |
| Dart SDK | ^3.12 |
| MySQL | 8.0+ |

### 2. 数据库

确保 MySQL 运行在 `localhost:3306`，执行以下 SQL：

```sql
CREATE DATABASE IF NOT EXISTS PuzzleGame;
USE PuzzleGame;
CREATE TABLE IF NOT EXISTS users (
  username VARCHAR(255) NOT NULL,
  phone VARCHAR(255) NOT NULL,
  password VARCHAR(255) NOT NULL,
  PRIMARY KEY (username, phone)
);
```

> **注意**：后端数据库连接配置在 `server/bin/server.dart` 第 10-17 行，如需修改请编辑该文件中的 `MySQLConnectionPool` 参数。

### 3. 启动后端

```bash
cd server
dart pub get
dart run bin/server.dart
```

后端默认运行在 **http://localhost:8080**，输出如下即成功：
```
MySQL 连接成功
服务器已启动：http://localhost:8080
```

### 4. 前端依赖

```bash
# 在项目根目录（sudoku/）执行
flutter pub get
```

---

## 🌐 运行到 Web 浏览器

```bash
# 启动开发服务器，自动打开浏览器
flutter run -d edge       # Microsoft Edge
flutter run -d chrome     # Google Chrome
```

Web 模式下前端自动连接 `http://localhost:8080/api`，**无需额外配置**。

> 如果后端不在本机，请修改 `lib/services/api_service.dart` 第 9 行的 `baseUrl`。

---

## 📱 运行到物理手机（Android）

### 第一步：连接手机

1. 手机开启 **开发者选项** 和 **USB 调试**
2. 用 USB 数据线连接电脑
3. 检查设备是否识别：

```bash
flutter devices
```

输出示例：
```
KOZ AL40 (mobile) • A7JC9X1705G05171 • android-arm64 • Android 10 (API 29)
```

### 第二步：ADB 端口转发

手机上的 `localhost` 指向手机自身，**不是电脑**。需要用 ADB 将手机端口转发到电脑：

```bash
adb reverse tcp:8080 tcp:8080
```

这条命令让手机访问 `localhost:8080` 时，实际连接到**电脑的 8080 端口**（即后端服务）。

> 每次重新插拔手机都需要重新执行此命令。建议手机保持 USB 连接不断开。

### 第三步：运行到手机

```bash
# 单设备时直接运行
flutter run

# 多设备时指定设备 ID
flutter run -d A7JC9X1705G05171
```

### 第四步：查看运行日志

运行后终端会显示调试日志，按以下快捷键操作：
- `r` — 热重载（修改代码后即时更新）
- `R` — 热重启
- `q` — 退出

---

## 📦 构建生产版本

### Web 构建

```bash
flutter build web
```

产物在 `build/web/` 目录，可用任意静态服务器部署：
```bash
# 使用 npx serve 预览
npx serve build/web
```

### Android APK 构建

```bash
# Debug 版（适合测试）
flutter build apk --debug

# Release 版（适合分发）
flutter build apk --release
```

APK 文件位置：`build/app/outputs/flutter-apk/app-release.apk`

> 安装到手机后需确保手机能访问到电脑后端（同局域网或 `adb reverse`）。

---

## 📁 项目结构

```
sudoku/
├── lib/
│   ├── main.dart                    # 入口 + 启动画面（自动登录检测）
│   ├── models/
│   │   ├── sudoku_game.dart         # 数独数据模型
│   │   └── sudoku_generator.dart    # 生成器 + 求解器
│   ├── screens/
│   │   ├── login_page.dart          # 登录
│   │   ├── register_page.dart       # 注册
│   │   ├── home_page.dart           # 首页（底部导航）
│   │   ├── game_page.dart           # 数独游戏核心
│   │   ├── rank_page.dart           # 排行榜
│   │   ├── profile_page.dart        # 个人中心
│   │   └── settings_page.dart       # 设置
│   ├── widgets/
│   │   └── sudoku_board.dart        # 数独棋盘组件
│   └── services/
│       └── api_service.dart         # API 请求封装
├── server/
│   └── bin/server.dart              # 后端服务（shelf）
└── web/                             # Web 入口
```

---

## 🎮 游戏操作

### 触屏操作
- **点击格子**：选中，弹出数字键盘
- **底部按钮**：新局 / 完成 / 求解 / 撤销 / 重置 / 重做
- **右上角图标**：切换笔记模式（点击数字添加到笔记，再次点击移除）

### 键盘操作（Web / 外接键盘）
- **数字键 1-9**：填入数字（4×4 模式还支持 A-G 对应 10-16）
- **退格 / Delete**：清除当前格
- **方向键**：移动选中格（需系统支持）

---

## ⚙️ 难度说明

每局游戏自动随机选取难度，遵循正态分布：

### 3×3（81 格）

| 难度 | 提示数 | 出现概率 | 说明 |
|------|--------|---------|------|
| 🟥 极简 | 17-22 | ~10% | 需高级技巧 |
| 🟧 困难 | 23-28 | ~25% | 适合有经验玩家 |
| 🟦 中等 | 29-32 | ~40% | 常见数独水平 |
| 🟩 简单 | 33-36 | ~25% | 新手入门 |

### 4×4（256 格）

| 难度 | 提示数 | 出现概率 |
|------|--------|---------|
| 🟧 困难 | 70-80 | ~25% |
| 🟦 中等 | 92-105 | ~50% |
| 🟩 简单 | 110-130 | ~25% |

---

## 📄 License

本项目基于 MIT 许可证开源 — 详见 [LICENSE](LICENSE) 文件。
