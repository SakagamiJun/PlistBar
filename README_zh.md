[English](README.md) | 简体中文

<div align="center">

# PlistBar

面向 macOS 的 `launchd` 菜单栏控制面板，适合希望在一个入口内完成 Launch Agents 与 Daemons 服务查看、启停管理、配置编辑与日志告警的用户。

<p>
  <img alt="Platform" src="https://img.shields.io/badge/macOS-14%2B-111111?style=flat&logo=apple" />
  <img alt="Swift" src="https://img.shields.io/badge/Swift-6.2-F05138?style=flat&logo=swift" />
  <img alt="Build" src="https://img.shields.io/badge/Build-SwiftPM-0A84FF?style=flat" />
  <img alt="i18n" src="https://img.shields.io/badge/i18n-zh--Hans%20%7C%20en-34C759?style=flat" />
  <img alt="Version" src="https://img.shields.io/github/v/release/SakagamiJun/PlistBar?style=flat&logo=github" />
  <img alt="License" src="https://img.shields.io/badge/License-GPL%20v3-blue.svg?style=flat" />
</p>

</div>

## 环境要求

- macOS 14.0 (Sonoma) 及以上版本
- 本地构建需要兼容 Swift 6.2 的 Xcode 16+ 或 Swift 命令行工具链
- 普通用户权限可直接管理 User Agents；管理 Global Agents 与 Global Daemons 查看需要对应权限，系统级变更需管理员或 root 权限

## 快速开始

### 方式一：使用 Homebrew 安装

```sh
brew tap SakagamiJun/tap
brew install --cask plistbar
```

### 方式二：安装发布版本

1. 从 [GitHub Releases](https://github.com/SakagamiJun/PlistBar/releases) 下载最新的 `PlistBar.zip`。
2. 解压并将 `PlistBar.app` 拖入 `Applications`（应用程序目录）。
3. 从 `Applications` 启动 PlistBar。
4. 启动后，PlistBar 将常驻在菜单栏，点击即可呼出服务控制面板。

### 方式三：从源码构建

1. 克隆仓库：

```sh
git clone https://github.com/SakagamiJun/PlistBar.git
cd PlistBar
```

2. 构建应用包：

```sh
make build
```

3. 如需生成可发布的归档包：

```sh
make dist
```

4. 启动构建出的应用：

```sh
make run
```

## 功能概览

### 1. 服务状态与作用域浏览

- **全作用域支持**：按 **User Agents**（`~/Library/LaunchAgents`）、**Global Agents**（`/Library/LaunchAgents`）以及 **Global Daemons**（`/Library/LaunchDaemons`）进行分类与切换。
- **实时运行状态**：直观展示服务状态（运行中、已加载但未运行、未加载停止、异常退出等），标注 PID 与最近退出码。
- **高效搜索与筛选**：支持按服务标识符（Label）、执行命令或 Plist 文件名实时搜索，支持按运行状态进行过滤。

### 2. 生命周期与进程控制

- **现代 API 与回退兼容**：采用现代 `launchctl bootstrap` / `bootout` 命令，并在必要时自动回退到 `load` / `unload`。
- **快速启停与重载**：支持 `kickstart -kp` 即时拉起服务、`kill SIGTERM` 安全停止服务。
- **KeepAlive 感知与安全保护**：针对配置有 `KeepAlive` 的服务进行针对性停止处理，避免无序反复拉起；对删除等高危操作提供二次确认。
- **便捷系统交互**：支持在 Finder 中快速定位 `.plist` 文件，或一键拷贝服务 Label 与文件绝对路径。

### 3. 可视化配置编辑与模板

- **表单化 Plist 编辑器**：无需手动编辑冗长的 XML，提供可视化的字段配置（Label、Program、Arguments、RunAtLoad、KeepAlive、StandardOutPath、StandardErrorPath、WorkingDirectory、EnvironmentVariables 等）。
- **内置常用场景模板**：预置基础后台常驻服务、定时循环执行任务（StartInterval / StartCalendarInterval）、路径变动监听器（WatchPaths）等典型模板，一键套用。
- **原子安全写入**：配置保存前经过语法校验，采用临时文件原子替换写入，防止配置损坏。

### 4. 实时日志与智能异常告警

- **标准输出与错误流监控**：实时追踪服务的 `StandardOutPath` 与 `StandardErrorPath` 日志。
- **内存安全流式读取**：严格限制尾部 64KB 滑动窗口读取与上限 500 行的定容缓冲区，防止庞大日志撑爆系统内存。
- **可视化规则构建器**：预设 `Fatal`、`Error`、`Exception`、`Panic`、`Crash` 等错误规则，支持自定义关键字匹配或高级正则表达式，并划分 Warning / Error 严重级别。
- **菜单栏图标告警联动**：触发日志告警时，菜单栏图标自动切换为警告或错误状态，配合 macOS 原生系统通知，异常不漏接。

### 5. 极致轻量与原生设计

- **NSPanel 悬浮面板**：采用无边框浮动面板与系统级 `.regularMaterial` 材质，搭配自适应高度与平滑过渡动画。
- **视口联动零空转**：面板收起时自动暂停后台轮询定时器并注销全局监听器，零后台资源占用，内存极其节省。
- **完整国际化**：内置简体中文（`zh-Hans`）与英文（`en`），跟随系统语言无缝切换。

## 许可证

本项目基于 [GNU GPL v3.0](LICENSE) 许可发布。
