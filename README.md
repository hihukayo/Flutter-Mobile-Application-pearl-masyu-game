# 数独 Sudoku

Flutter 数独移动应用，支持用户登录注册、数独游戏、排行榜、个人中心等功能。

## 功能

- **用户系统**：注册/登录（后端 MySQL 存储）
- **数独游戏**：随机生成唯一题解，计时暂停、错误限制（3 次）、笔记模式、撤销擦除
- **排行榜**：按分数排名
- **个人中心**：修改用户名、密码、手机号

## 游戏特性

- 原生数字键盘输入，点击空格自动弹出
- 错误计数 0/3，超限游戏结束
- 笔记模式：候选数字标记（左上角蓝色小字）
- 计时器暂停/继续
- 撤销、重置、擦除
- 自动求解
- 题目粗黑、用户填入正确绿色/错误红色
- 触感反馈（HapticFeedback）
- Montserrat 无衬线字体

## 技术栈

- **前端**：Flutter (Dart)
- **后端**：Dart shelf + shelf_router
- **数据库**：MySQL
- **字体**：Google Fonts (Montserrat)

## 快速开始

### 1. 数据库

确保 MySQL 运行在 `localhost:3306`，创建数据库：

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

### 2. 启动后端

```bash
cd server
dart pub get
dart run bin/server.dart
```

后端运行在 `http://localhost:8080`。

### 3. 启动前端

```bash
flutter pub get
flutter run -d edge     # 浏览器运行
flutter run             # 连接设备运行
```

### 4. Web 构建

```bash
flutter build web
npx serve build/web
```

## 项目结构

```
lib/
├── main.dart              # 入口
├── models/
│   ├── sudoku_game.dart   # 数独数据模型
│   └── sudoku_generator.dart  # 生成器+求解器
├── screens/
│   ├── login_page.dart    # 登录
│   ├── register_page.dart # 注册
│   ├── home_page.dart     # 首页（底部导航）
│   ├── game_page.dart     # 数独游戏
│   ├── rank_page.dart     # 排行榜
│   ├── profile_page.dart  # 个人中心
│   └── settings_page.dart # 设置
├── widgets/
│   └── sudoku_board.dart  # 数独棋盘组件
└── services/
    └── api_service.dart   # API 请求封装
server/
└── bin/server.dart        # 后端服务
```
