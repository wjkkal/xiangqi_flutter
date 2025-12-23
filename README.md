# 中国象棋（Xiangqi Flutter）

一个使用 Flutter 编写的中国象棋开源应用，支持本地对战、AI 提示、悔棋、新开局等功能，并集成开源象棋引擎 Pikafish 以提供强大的搜索与评估能力。适合学习、二次开发与开源分发。

---

## 功能特性
- 棋盘对弈：支持红黑双方走子，规则校验与合法着生成。
- AI 能力：接入第三方引擎 Pikafish，提供提示与评估（无需联网）。
- 提示与悔棋：一键获取当前局面的 AI 提示；支持悔棋与新开局。
- 设置与体验：
  - 音效音量（本地音效）
  - 提示难度（影响 AI 建议强度）
  - 震动反馈（移动/吃子反馈）
- 隐私与开源：移除了广告与 mTLS/私有证书等敏感依赖；仅本地运行。
- 跨平台：以 Flutter 为基础，优先支持 Android；其余平台可按需扩展。

---

## 快速开始

### 环境准备
- Flutter（建议稳定版，3.x 及以上）
- Dart SDK（随 Flutter 安装）
- Android 构建环境（Android SDK、平台工具、已安装的设备或模拟器）
- 可选：Java JDK（随 Android/Gradle 自动管理即可）

### 拉取依赖并运行
```bash
# 拉取依赖
flutter pub get

# 运行到已连接设备或模拟器
flutter run

# 代码静态检查
flutter analyze

# 构建 Android APK（调试）
flutter build apk --debug

# 构建 Android APK（发布）
flutter build apk --release
```

> 提示：首轮构建会自动编译 JNI/C++ 侧的引擎桥接与原生代码；如遇到 Android NDK/SDK 的环境问题，按 `flutter doctor` 的提示进行安装/修复。

---

## 项目结构
- `lib/`：Dart/Flutter 应用代码
  - `main.dart`：应用入口与主界面
  - `controllers/`：对局控制、规则校验、AI 管理等
  - `widgets/`：UI 组件（棋盘、底栏、信息面板、对话框等）
  - `services/`：服务层（如反馈、本地客户端等）
  - `utils/`：工具与设置（声音、设备信息、持久化等）
- `assets/`：资源（图片、音效、开局库等）
- `android/`：Android 原生工程与 JNI/C++ 绑定
- `third_party/pikafish/`：Pikafish 引擎源码与依赖（GPLv3）
- `tool/`、`scripts/`：辅助脚本与工具

---

## 第三方引擎：Pikafish
- 位置：`third_party/pikafish/`
- 说明：Pikafish 为开源的中国象棋/国际象棋家族引擎，具备高效搜索与评估能力；本项目通过 JNI/FFI 等桥接机制在 Flutter 中调用其 UCI 接口以获取着法建议与评估结果。
- 许可：Pikafish 使用 GNU GPL v3 协议分发；见 `third_party/pikafish/Copying.txt` 与其上游仓库说明。
- 参考：上游仓库 README 提到的链接（例如 `https://github.com/official-pikafish/Pikafish#readme`）可获取更多背景和用法说明。

---

## 体系结构概览
- Flutter 前端：
  - `GameBoard`（棋盘）负责绘制棋盘与棋子、处理用户交互。
  - `BottomActionBar`（底部栏）提供“新游戏 / 悔棋 / 提示”等操作按钮。
  - `SettingsDialog`（设置）管理音效、提示难度、震动等选项。
- 控制与规则：
  - `GameController` 维护局面状态（轮次、走子、悔棋栈等）并协调 AI 提示。
  - `MoveValidator` 等组件负责规则合法性与走法生成。
- 引擎桥接：
  - 通过 `pigeons/` 生成的桥接代码与 Android JNI/C++ 层交互，调用 Pikafish 的 UCI 接口。

---

## 贡献与开发
- 欢迎通过 Issue 或 PR 提交修复与改进。
- 代码风格：遵循 Flutter/Dart 规范与项目现有风格；提交前建议运行：
```bash
flutter analyze
flutter test  # 如后续加入单元测试
```
- 功能建议：如需新增平台支持或改进引擎交互，欢迎在 Issue 中讨论方案与兼容性。

---

## 许可证（License）
本项目及其第三方引擎 `third_party/pikafish` 使用 **GNU GENERAL PUBLIC LICENSE Version 3 (GPLv3)** 分发。

重要说明：
- 本仓库包含 Pikafish 的完整源代码（`third_party/pikafish/`），其许可为 GPLv3。根据 GPLv3 的条款，包含 GPLv3 代码的派生或组合分发必须在相同的 GPLv3 许可证下提供源代码与许可条款。
- 我们已在仓库根添加完整的 `LICENSE`（GPLv3 正文），并在 `third_party/pikafish/Copying.txt` 中保留了原始引擎的版权与许可声明。

分发合规清单（简明）：
- 如你要分发已编译的二进制（APK 等），请同时提供或指向完整的源代码（例如本仓库 URL）。
- 保留并分发本仓库中的 `LICENSE` 文件与 `third_party/pikafish/Copying.txt`，确保接收者能查看 GPLv3 条款。
- 若你修改了 Pikafish 的源文件，请在修改处注明变更并保留原始版权声明（参见 GPLv3 第 5 条）。
- 我们还在 `THIRD_PARTY_LICENSES.md` 中列出了第三方组件与其许可证，便于分发时核对。

如果你需要，我可以为 README 添加一段“如何在应用 About 界面显示许可信息”的示例文字，或在代码中添加一个“关于”对话框模板来显示许可与作者信息。

---

## 致谢
- Pikafish 引擎及其维护者社区。
- Flutter/Dart 生态与开源社区的所有贡献者。
