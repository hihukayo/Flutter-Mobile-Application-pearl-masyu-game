# 🧩 数独 Sudoku

Flutter 数独移动应用，支持用户登录注册、经典/杀手数独、云存档、积分排行榜、个人中心等功能。

## ✨ 功能

- **用户系统**：注册 / 登录（后端 MySQL 存储，密码 SHA256 加密）
- **数独游戏**：
  - 3×3 经典九宫格 & 4×4 十六进制数独
  - **杀手数独**（3×3）：虚线框（Cage）+ 和值模式，支持异形笼子
  - **难度自动随机**：遵循正态分布，避免连续重复
  - 计时器、暂停 / 继续（暂停时自动存档）
  - 笔记模式（候选数字标记）
  - 撤销 / 重做（支持笔记操作）
  - 错误计数（3×3 限 3 次，4×4 限 6 次）
  - **云存档**：保存/读档游戏进度（手动 + 自动）
  - 自动求解、重置
- **积分系统**：每局游戏根据难度、用时、错误数计算积分
  - 公式：`基础分 × 难度系数 × 时间加成 × 错误惩罚`
  - 排行榜按总积分排名，显示胜率
- **音效与震动**：按钮震动 + 原生音效（正弦波/MP3）
- **自动收起键盘**：填满格子或游戏结束时自动隐藏
- **按键防抖**：300ms 消抖，防止误触
- **排行榜**：按总积分排名
- **个人中心**：总局数/总积分/胜率、修改用户名/密码/手机号、注销账号、头像

## 🛠 技术栈

| 层级 | 技术 |
| --- | --- |
| 前端 | Flutter (Dart) |
| 后端 | Dart shelf + shelf_router |
| 数据库 | MySQL |
| 音效 | Android AudioTrack / MediaPlayer / audioplayers (Web) |

---

## 🚀 快速启动

### 环境要求

| 工具 | 版本要求 |
| --- | --- |
| Flutter | ^3.12 |
| Dart SDK | ^3.12 |
| MySQL | 8.0+ |

### 一键启动（推荐）

项目根目录下的 `run.bat` 提供菜单式启动：

```
  [1]  Install to Phone
  [2]  Launch Web App (auto-start backend)
  [3]  Start Backend Only
  [4]  Stop Backend
  [5]  Exit
```

- **选 `[2]`** → 自动构建前端 + 启动后端 → 浏览器打开 http://127.0.0.1:8080
  - 前后端同端口，无跨域问题
  - 生产模式，如需热重载请单独运行 `flutter run -d edge`
- **选 `[1]`** → 检测手机 → ADB 端口转发 → 安装运行
- **选 `[3]`** → 单独启动后端
- **选 `[4]`** → 停止后端

> 确保 Flutter SDK 已加入 `PATH`（如 `D:\Flutter\bin`），或在 `run.bat` 中已设置。

### 手动启动

**数据库：**
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

**后端：**
```bash
cd server
dart pub get
dart run bin/server.dart
# 输出：MySQL 连接成功 → 服务器已启动
```

**前端依赖：**
```bash
flutter pub get
```

**Web 浏览器（构建模式）：**
```bash
flutter build web --release
cd server
dart run bin/server.dart
# 打开 http://127.0.0.1:8080
```

**物理手机（Android）：**
```bash
# 1. 手机开启 USB 调试并连接电脑
# 2. ADB 端口转发
adb reverse tcp:8080 tcp:8080
# 3. 安装
flutter run -d <device_id>
```

---

## 💾 存档系统

- **自动存档**：暂停游戏时自动保存进度
- **手动存档/读档**：游戏页面底部「存档」「读档」按钮
- **续玩**：进入游戏时自动检测存档，弹窗询问是否继续
- **云端存储**：存档保存在服务器 MySQL，换设备可恢复

## 🏆 积分系统

每局游戏结束后自动计算积分：

```
最终得分 = 基础分 × 难度系数 × 时间加成 × 错误惩罚
```

**基础分（含模式系数）：**
| 模式 | 基础分 |
|------|--------|
| 9×9 常规 | 100 |
| 9×9 杀手 | 200 |
| 16×16 常规 | 250 |

**难度系数：**
| 难度 | 系数 |
|------|------|
| 简单 / 入门 | 1.0 |
| 中等 | 1.5 |
| 困难 / 极简 | 2.0 |

**时间加成：**
```
(标准耗时 / 实际耗时) × 0.5 + 0.5    取值 [0.5, 5.0]
```

**错误惩罚：**
```
(最大允许错误 - 实际错误) / 最大允许错误
```
3×3 模式最大 3 次错误，4×4 模式最大 6 次错误。

---

## 📁 项目结构

```
sudoku/
├── lib/
│   ├── main.dart                    # 入口 + 启动画面
│   ├── models/
│   │   ├── sudoku_game.dart         # 数据模型（含 Cage）
│   │   └── sudoku_generator.dart    # 生成器 + 求解器
│   ├── screens/
│   │   ├── login_page.dart          # 登录
│   │   ├── register_page.dart       # 注册
│   │   ├── home_page.dart           # 首页（底部导航）
│   │   ├── game_page.dart           # 游戏核心（含杀手数独、存档/读档）
│   │   ├── rank_page.dart           # 排行榜（积分 + 胜率）
│   │   ├── profile_page.dart        # 个人中心
│   │   └── settings_page.dart       # 设置
│   ├── widgets/
│   │   └── sudoku_board.dart        # 棋盘组件（含 Cage 绘制）
│   └── services/
│       └── api_service.dart         # API 请求封装
├── assets/
│   └── audio/
│       ├── click.wav                # 按钮点击（Web）
│       ├── success.wav              # 游戏完成（Web）
│       ├── Placement.mp3            # 填入/删除数字
│       └── failed.mp3               # 游戏失败
├── server/
│   ├── bin/server.dart              # 后端服务（shelf + MySQL）
│   ├── pubspec.yaml
│   └── pubspec.lock
├── web/                             # Web 入口
└── run.bat                          # 一键启动器（根目录）
```

---

## 📄 License

本项目基于 GNU General Public License v3.0 (GPLv3) 开源 — 详见 [LICENSE](LICENSE) 文件。
