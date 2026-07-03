# Agent Skills 配置说明

## 1. 配置来源

本项目按照 Flutter 官方文档 `https://docs.flutter.dev/ai/agent-skills` 配置项目级 Agent Skills。

官方文档说明：兼容 Agent 默认从项目工作区的 `.agents/skills` 目录发现 skills；Flutter 与 Dart 官方团队分别维护 `flutter/skills` 和 `dart-lang/skills` 仓库。

## 2. 已安装内容

本次配置新增：

- `.agents/skills/flutter-*`：Flutter 官方 skills，共 10 个。
- `.agents/skills/dart-*`：Dart 官方 skills，共 11 个。
- `.agents/skills/qsdms-desktop-project`：本项目专用 skill，用于约束 `QSDMS_DESKTOP` 的目录、技术栈、中文可见文案、验证命令和安全边界。
- `skills-lock.json`：`skills` CLI 生成的锁定文件，用于记录已安装 skills 的来源和哈希。

## 3. 恢复与更新命令

从 `skills-lock.json` 恢复官方 skills：

```bash
npx -y skills experimental_install
```

查看当前项目 skills：

```bash
npx -y skills list --json
```

更新项目级 skills：

```bash
npx -y skills update --project --yes
```

## 4. 使用约束

- 做 Flutter/Dart 任务前，优先让 Agent 查看 `.agents/skills/qsdms-desktop-project`，再按任务选择对应的官方 `flutter-*` 或 `dart-*` skill。
- `dart-setup-ffi-assets` 在安装时被 `skills` CLI 标记为 `Critical Risk`。该 skill 来自 Dart 官方仓库，但本项目当前没有明确 FFI / C / C++ native assets 需求，因此只有在任务明确涉及 FFI、native assets 或 C/C++ interop 时才使用。
- 删除官方 skill 属于删除文件，按照项目规则需要先获得确认。

## 5. 验证命令

本次 skills 配置的最小验证命令：

```bash
npx -y skills list --json
python3 -c 'from pathlib import Path; import re; text = Path(".agents/skills/qsdms-desktop-project/SKILL.md").read_text(); assert re.match(r"^---\n(?s:.*?)\n---", text); assert "name: qsdms-desktop-project" in text; assert "description:" in text'
git diff --check -- .agents/skills/qsdms-desktop-project skills-lock.json docs/agent-skills配置说明.md
```

说明：Flutter/Dart 官方导入的 `SKILL.md` 属于第三方 vendor 内容，若其原始文件存在行尾空格，不为通过空白检查而直接改写官方内容。
