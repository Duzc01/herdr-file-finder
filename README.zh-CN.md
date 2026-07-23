# herdr-file-finder

[English](README.md)

一个 herdr 插件：按下快捷键，在当前工作目录弹出一个居中弹窗，模糊查找文件，
选中后按你喜欢的方式打开。

默认打开动作交给 **Warp**（作者的终端）处理：在新标签页按文件类型路由——
Markdown 走 Warp 的原生渲染视图，代码/文本走内置编辑器。打开动作只是一行
配置，随时可换成 VS Code、Cursor、`$EDITOR` 或任意命令。

![screenshot](docs/screenshot.png)

## 特性

- **模糊查找**：`fd`（尊重 `.gitignore`）+ `fzf`，输入即过滤
- **右侧实时预览**：`bat` 语法高亮预览选中文件
- **打开动作可自定义**：一个配置项决定选中后做什么——任意命令模板，
  支持 `{uri}` / `{path}` / `{dir}` 占位符
- **零构建**：纯 Bash 脚本，`herdr plugin link` 即用

## 依赖

```bash
brew install fd fzf jq bat
```

`bat` 仅用于预览，缺失时回退到 `cat`；其余三个为必需。

## 安装

```bash
# 1. 克隆/放置插件目录后，链接进 herdr（link 是引用而非拷贝，改文件即生效）
herdr plugin link /path/to/herdr-file-finder
```

2. 在 `~/.config/herdr/config.toml` 中绑定快捷键（追加）：

```toml
[[keys.command]]              # fuzzy-find a file, open it in a new Warp tab
key = "prefix+o"
type = "shell"
command = "herdr plugin action invoke find-file --plugin herdr-file-finder"
```

验证：`herdr plugin list` 应显示 `herdr-file-finder … enabled`。

## 使用

| 按键 | 行为 |
| --- | --- |
| `prefix+o` | 弹出查找弹窗（以你当前窗格的工作目录为根） |
| 输入字符 | 模糊过滤文件列表 |
| `↑` / `↓` | 移动选择 |
| `Enter` | 按配置的动作打开选中文件 |
| `Esc` | 关闭弹窗 |

## 自定义配置

配置文件（可选）：`~/.config/herdr/plugins/config/herdr-file-finder/config.toml`
（用 `herdr plugin config-dir herdr-file-finder` 查看目录）。完整示例见
[`config.example.toml`](config.example.toml)。

### 自定义打开动作

一个 `open` 键，值是命令模板（选中后经 `bash -c` 执行）。不建配置文件时
使用默认模板：在 Warp 新标签页打开。

```toml
open = 'open "warp://action/new_tab?path={uri}"'
```

占位符：

| 占位符 | 含义 |
| --- | --- |
| `{uri}` | URL 编码后的绝对路径（用于 `warp://` URI） |
| `{path}` | 原始绝对路径（注意自行加引号：`"{path}"`） |
| `{dir}` | 选中文件所在目录 |

常用模板：

```toml
# Warp 新标签页（MD→渲染视图，代码→内置编辑器）——默认
open = 'open "warp://action/new_tab?path={uri}"'

# Warp 内置编辑器（可加 &line=N 跳行）
open = 'open "warp://action/open_file_editor?path={uri}"'

# VS Code / Cursor
open = 'code "{path}"'
open = 'cursor "{path}"'

# macOS 默认应用
open = 'open "{path}"'
```

推荐用 TOML 单引号字面字符串（模板本身含双引号，省去转义）；双引号写法
（`\"` 转义）也支持。

### 其他可调项（改 `src/`）

- **弹窗尺寸**：`src/open-file-finder.sh` 里的 `--width 70% --height 60%`
- **预览栏比例**：`src/finder.sh` 里 `--preview-window 'right,60%,border-left'`
- **是否包含隐藏文件**：`src/finder.sh` 里给 `fd` 加 `--hidden --exclude .git`

## 工作原理

1. `prefix+o` → herdr action `find-file` → `src/open-file-finder.sh`
2. 启动器从 `HERDR_PLUGIN_CONTEXT_JSON` 读取当前焦点窗格的 cwd，以 popup
   形式（70%×60%，居中）打开 `file-finder` 入口并聚焦
3. 弹窗内运行 `src/finder.sh`：`fd --type f` 喂给 `fzf`；`Esc` 或空选择
   直接退出，herdr 自动关闭弹窗
4. 选中后绝对路径经 `jq @uri` 编码，代入 `open` 模板执行。默认模板调用
   Warp 的 `warp://action/new_tab` URI，按文件类型路由：Markdown → 渲染
   视图；代码/文本 → 内置编辑器；目录 → 终端会话

## 卸载

```bash
herdr plugin unlink herdr-file-finder
# 并删除 ~/.config/herdr/config.toml 中 [[keys.command]] 的那一段绑定
```
