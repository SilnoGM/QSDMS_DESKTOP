# window_manager 能力说明文档

> 版本基准：`window_manager 0.5.1`  
> 适用项目：Flutter Desktop 应用，重点覆盖 `Linux`、`macOS`、`Windows`  
> 编写日期：2026-07-02

## 1. 这个库是干什么用的

`window_manager` 是一个 Flutter Desktop 窗口管理插件。它不负责业务页面、不负责路由、不负责数据存储，而是负责控制桌面应用外层原生窗口。

它能做的事情主要包括：

- 设置窗口启动尺寸、最小尺寸、最大尺寸。
- 控制窗口显示、隐藏、聚焦、关闭、销毁。
- 控制窗口位置、居中、对齐、边界。
- 控制最大化、最小化、全屏、恢复。
- 控制标题栏、无边框、阴影、透明度、背景色、标题、图标。
- 控制窗口是否可拖动、可缩放、可关闭、可最小化、可最大化。
- 拦截关闭事件，例如关闭前弹出确认框。
- 监听窗口焦点、移动、缩放、最大化、最小化、全屏等事件。
- 提供自定义标题栏拖动区域和缩放区域组件。

它适合用在需要运行时控制窗口行为的桌面应用里，例如管理系统、工具软件、客户端应用。

## 2. 当前项目是否必须使用它

当前 `QSDMS_DESKTOP` 已经通过原生 runner 配置完成了这些启动级需求：

- 默认启动尺寸：`1440 x 810`
- 窗口标题置空
- macOS 标题文字隐藏

这些都是启动时固定配置，直接改 `macos` / `windows` runner 更简单、更稳定，不一定需要引入 `window_manager`。

如果后续出现这些需求，再考虑引入：

- 启动后自动居中。
- 用户调整窗口大小后记住尺寸。
- 运行时切换全屏、最大化、最小化。
- 关闭窗口前弹确认框。
- 自定义标题栏和拖拽区域。
- 隐藏到任务栏或 Dock。
- 控制窗口置顶。

## 3. 安装和初始化

官方安装方式：

```yaml
dependencies:
  window_manager: ^0.5.1
```

典型初始化代码：

```dart
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1440, 810),
    center: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}
```

关键点：

- `WidgetsFlutterBinding.ensureInitialized()` 必须在调用插件前执行。
- `windowManager.ensureInitialized()` 用于初始化插件。
- `waitUntilReadyToShow()` 用于等窗口配置准备好后再显示，减少启动闪烁。
- `runApp()` 通常放在窗口准备逻辑之后或附近，具体要结合项目启动流程。

## 4. WindowOptions：启动窗口配置

`WindowOptions` 用来描述窗口显示前的初始配置。它适合做启动时一次性配置。

| 配置项 | 作用 | 典型用途 |
|---|---|---|
| `size` | 设置启动窗口尺寸 | 默认 `1440 x 810` |
| `center` | 是否启动后居中 | 桌面管理系统通常建议开启 |
| `minimumSize` | 设置最小窗口尺寸 | 防止表格、侧边栏被压到不可用 |
| `maximumSize` | 设置最大窗口尺寸 | 特殊工具窗口限制尺寸 |
| `alwaysOnTop` | 是否置顶 | 小工具、悬浮控制台 |
| `fullScreen` | 是否全屏启动 | 看板、展示屏 |
| `backgroundColor` | 设置窗口背景色 | 透明窗口、无边框窗口 |
| `skipTaskbar` | 是否不显示在任务栏 / Dock | 后台辅助窗口、托盘应用 |
| `title` | 设置原生窗口标题 | 普通桌面应用标题 |
| `titleBarStyle` | 设置标题栏样式 | 隐藏标题栏、自定义标题栏 |
| `windowButtonVisibility` | 控制窗口按钮是否显示 | 隐藏或保留关闭、最小化、最大化按钮 |

注意：

- 如果只是静态默认尺寸，原生 runner 也可以设置，不一定要引入插件。
- 如果要运行时动态修改尺寸、居中、标题栏，再使用 `window_manager` 更合适。

## 5. WindowManager：核心管理器

`windowManager` 是 `WindowManager.instance` 的快捷变量。大部分窗口操作都通过它完成。

### 5.1 初始化和监听

| API | 作用 | 使用场景 |
|---|---|---|
| `ensureInitialized()` | 初始化插件 | `main()` 启动阶段必须先调用 |
| `waitUntilReadyToShow(options, callback)` | 等窗口准备好后再显示 | 设置尺寸、居中、标题栏后再展示 |
| `addListener(listener)` | 添加窗口事件监听器 | 监听关闭、移动、缩放、聚焦等 |
| `removeListener(listener)` | 移除窗口事件监听器 | 页面销毁或服务释放时清理监听 |
| `hasListeners` | 是否存在监听器 | 调试或封装窗口服务时检查 |
| `listeners` | 当前监听器列表 | 一般业务不直接使用 |

### 5.2 显示、隐藏、聚焦和关闭

| API | 作用 | 使用场景 |
|---|---|---|
| `show({ inactive = false })` | 显示窗口 | 启动后显示、从隐藏状态恢复 |
| `hide()` | 隐藏窗口 | 最小化到后台、托盘应用 |
| `focus()` | 聚焦窗口 | 点击 Dock / 托盘后拉回前台 |
| `blur()` | 取消窗口焦点 | 特殊自动化或辅助场景 |
| `close()` | 请求关闭窗口 | 触发正常关闭流程，可被拦截 |
| `destroy()` | 强制销毁窗口 | 不走普通关闭流程，谨慎使用 |
| `isVisible()` | 判断窗口是否可见 | 托盘菜单切换显示 / 隐藏 |
| `getId()` | 获取窗口 ID | 单窗口场景很少用，多窗口协作时有价值 |

建议：

- 普通关闭优先使用 `close()`。
- `destroy()` 更接近强制关闭，可能绕过业务确认逻辑，少用。

### 5.3 尺寸、位置和边界

| API | 作用 | 使用场景 |
|---|---|---|
| `getSize()` | 获取当前窗口尺寸 | 保存用户窗口偏好 |
| `setSize(size, { animate })` | 设置窗口尺寸 | 切换紧凑模式 / 宽屏模式 |
| `getPosition()` | 获取窗口左上角位置 | 记住用户窗口位置 |
| `setPosition(position, { animate })` | 设置窗口位置 | 恢复上次位置 |
| `getBounds()` | 获取窗口位置和尺寸 | 一次性保存完整窗口状态 |
| `setBounds(bounds, { position, size, animate })` | 同时设置位置和尺寸 | 恢复用户上次窗口状态 |
| `center({ animate })` | 将窗口居中 | 启动后居中、重置窗口 |
| `setAlignment(alignment, { animate })` | 按屏幕对齐窗口 | 贴左、贴右、居中展示 |
| `setMinimumSize(size)` | 设置最小尺寸 | 防止界面被压坏 |
| `setMaximumSize(size)` | 设置最大尺寸 | 限制工具窗口 |
| `setAspectRatio(ratio)` | 固定窗口宽高比 | 视频、预览、固定比例工具 |
| `getDevicePixelRatio()` | 获取设备像素比 | 处理高分屏尺寸计算 |

对管理系统的建议：

- 建议设置 `minimumSize`，避免表格和侧边栏被压到不可用。
- 不建议强制 `setAspectRatio(16 / 9)`，因为用户可能需要自由调整窗口大小。
- 如果要记住窗口状态，使用 `getBounds()` + 本地存储，比只存 `getSize()` 更完整。

### 5.4 最大化、最小化、全屏和恢复

| API | 作用 | 使用场景 |
|---|---|---|
| `maximize({ vertically = false })` | 最大化窗口 | 主工作台一键最大化 |
| `unmaximize()` | 退出最大化 | 恢复普通窗口 |
| `isMaximized()` | 判断是否最大化 | 控制 UI 按钮状态 |
| `minimize()` | 最小化窗口 | 最小化到任务栏 / Dock |
| `isMinimized()` | 判断是否最小化 | 状态同步 |
| `restore()` | 从最小化等状态恢复 | 点击托盘 / Dock 后恢复 |
| `setFullScreen(bool)` | 设置全屏 | 展示大屏、沉浸式页面 |
| `isFullScreen()` | 判断是否全屏 | 切换按钮状态 |

注意：

- `maximize(vertically: true)` 的垂直最大化模拟 Windows 的 Aero Snap，只适用于 Windows。
- 全屏和最大化不是一回事。全屏通常隐藏系统窗口边框，最大化仍是普通窗口状态。

### 5.5 Windows Dock 能力

| API | 作用 | 平台 |
|---|---|---|
| `dock({ side, width })` | 将窗口停靠到屏幕一侧 | Windows |
| `undock()` | 取消停靠 | Windows |
| `isDockable()` | 判断是否可停靠 | Windows 为主 |
| `isDocked()` | 判断是否已停靠 | Windows 为主 |

这个能力更适合工具栏、侧边辅助面板，不是普通管理系统的核心需求。

## 6. 标题栏、外观和图标

### 6.1 标题和标题栏

| API | 作用 | 使用场景 |
|---|---|---|
| `setTitle(title)` | 设置原生窗口标题 | 显示当前项目名、环境名 |
| `getTitle()` | 获取原生窗口标题 | 调试或状态同步 |
| `setTitleBarStyle(style, { windowButtonVisibility })` | 设置标题栏样式 | 隐藏标题栏、自定义标题栏 |
| `getTitleBarHeight()` | 获取标题栏高度 | 自定义布局避让 |
| `setAsFrameless()` | 移除窗口边框和标题栏 | 完全自定义窗口外壳 |

`TitleBarStyle` 常见用途：

- `TitleBarStyle.normal`：使用系统默认标题栏。
- `TitleBarStyle.hidden`：隐藏标题栏，但通常保留窗口控制能力。

注意：

- 自定义标题栏意味着要自己处理拖动区域、按钮、双击最大化等交互。
- 如果只是隐藏标题文字，原生 runner 也能做；如果要运行时切换标题栏样式，用插件更方便。

### 6.2 外观控制

| API | 作用 | 使用场景 |
|---|---|---|
| `setBackgroundColor(color)` | 设置窗口背景色 | 透明窗口、无边框窗口背景 |
| `setBrightness(brightness)` | 设置窗口亮暗模式 | 跟随主题调整系统外观 |
| `setOpacity(opacity)` | 设置窗口透明度 | 悬浮窗、临时提示窗 |
| `getOpacity()` | 获取当前透明度 | UI 状态同步 |
| `setHasShadow(bool)` | 设置窗口阴影 | 无边框窗口保留层次感 |
| `hasShadow()` | 判断是否有阴影 | 调试、状态同步 |
| `setIcon(iconPath)` | 设置窗口 / 任务栏图标 | 动态换图标 |
| `setBadgeLabel([label])` | 设置 Dock / 任务栏徽标文字 | 未读数、任务进度 |
| `popUpWindowMenu()` | 弹出窗口系统菜单 | 自定义标题栏里模拟右键系统菜单 |

注意：

- 阴影在 Windows 上通常只有无边框窗口才更有意义。
- 透明窗口和无边框窗口会增加平台差异，必须分别在 macOS / Windows / Linux 验证。

## 7. 窗口能力开关

这些 API 用来控制用户是否能对窗口执行某些操作。

| API | 作用 | 使用场景 |
|---|---|---|
| `setResizable(bool)` | 设置是否允许缩放 | 固定尺寸工具窗口 |
| `isResizable()` | 判断是否可缩放 | 同步 UI 状态 |
| `setMovable(bool)` | 设置是否允许移动 | 锁定展示屏窗口 |
| `isMovable()` | 判断是否可移动 | 状态同步 |
| `setMinimizable(bool)` | 设置是否允许最小化 | 强约束流程窗口 |
| `isMinimizable()` | 判断是否可最小化 | 状态同步 |
| `setMaximizable(bool)` | 设置是否允许最大化 | 固定尺寸窗口 |
| `isMaximizable()` | 判断是否可最大化 | 状态同步 |
| `setClosable(bool)` | 设置是否允许用户关闭 | 安装器、关键流程 |
| `isClosable()` | 判断是否可关闭 | 状态同步 |
| `setPreventClose(bool)` | 拦截关闭信号 | 关闭前确认、保存未完成表单 |
| `isPreventClose()` | 判断是否拦截关闭 | 状态同步 |
| `setIgnoreMouseEvents(ignore, { forward })` | 让窗口忽略鼠标事件 | 透明覆盖层、点击穿透窗口 |

关闭拦截示例：

```dart
class AppWindowListener with WindowListener {
  @override
  void onWindowClose() async {
    final shouldClose = await confirmBeforeClose();
    if (shouldClose) {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    }
  }
}
```

使用关闭拦截时需要注意：

- 启动时先调用 `setPreventClose(true)`。
- 在 `onWindowClose()` 里做确认。
- 用户确认后先取消拦截，再调用 `close()`。

## 8. 置顶、任务栏和工作区

| API | 作用 | 使用场景 |
|---|---|---|
| `setAlwaysOnTop(bool)` | 设置窗口置顶 | 小工具、浮动控制台 |
| `isAlwaysOnTop()` | 判断是否置顶 | 按钮状态同步 |
| `setAlwaysOnBottom(bool)` | 设置窗口总在底部 | 桌面背景类窗口 |
| `isAlwaysOnBottom()` | 判断是否总在底部 | 状态同步 |
| `setSkipTaskbar(bool)` | 设置是否跳过任务栏 / Dock | 托盘应用、后台窗口 |
| `isSkipTaskbar()` | 判断是否跳过任务栏 | 状态同步 |
| `setVisibleOnAllWorkspaces(bool, { visibleOnFullScreen })` | 设置是否在所有工作区可见 | 跨桌面悬浮工具 |
| `isVisibleOnAllWorkspaces()` | 判断是否所有工作区可见 | 状态同步 |

管理系统建议：

- 默认不要置顶，避免干扰用户处理其他工作。
- 默认不要 `skipTaskbar`，否则用户可能找不到窗口。
- `visibleOnAllWorkspaces` 适合悬浮工具，不适合普通业务系统主窗口。

## 9. 拖动、缩放和自定义标题栏组件

`window_manager` 提供一些 Flutter Widget，帮助实现自定义窗口外壳。

| 组件 / API | 作用 | 使用场景 |
|---|---|---|
| `DragToMoveArea` | 包裹一个区域，使其可拖动窗口 | 自定义标题栏拖动区 |
| `DragToResizeArea` | 包裹边缘区域，使其可拖拽缩放 | 自定义边框缩放 |
| `startDragging()` | 代码触发窗口拖动 | 自定义标题栏手势 |
| `startResizing(edge)` | 代码触发窗口缩放 | 自定义边缘缩放手势 |
| `VirtualWindowFrame` | 虚拟窗口框架 | 自定义窗口外观 |
| `VirtualWindowFrameInit()` | 初始化虚拟窗口框架的 builder | 全局包装自定义窗口框架 |
| `WindowCaption` | 模拟 Windows 11 标题栏 | Windows 风格自定义标题栏 |
| `WindowCaptionButton` | 标题栏按钮 | 自定义最小化、最大化、关闭按钮 |
| `WindowCaptionButtonIcon` | 标题栏按钮图标 | 配合 `WindowCaptionButton` 使用 |

注意：

- 一旦使用自定义标题栏，就要认真处理平台体验差异。
- macOS 用户习惯左侧窗口按钮，Windows 用户习惯右侧窗口按钮。
- 自定义标题栏要保证拖动、双击最大化、窗口按钮、键盘可访问性都可用。

## 10. Linux 键盘抓取能力

| API | 作用 | 平台 |
|---|---|---|
| `grabKeyboard()` | 抓取键盘输入 | Linux |
| `ungrabKeyboard()` | 释放键盘输入 | Linux |

这类能力适合快捷键密集型工具，不是普通管理系统的常规需求。

## 11. WindowListener：窗口事件监听

`WindowListener` 用于响应原生窗口事件。可以把它封装到一个服务类里，在应用启动时注册。

| 事件方法 | 触发时机 | 常见用途 |
|---|---|---|
| `onWindowEvent(eventName)` | 任意窗口事件 | 统一日志、调试 |
| `onWindowFocus()` | 窗口获得焦点 | 刷新状态、恢复快捷键 |
| `onWindowBlur()` | 窗口失去焦点 | 暂停某些操作 |
| `onWindowClose()` | 窗口将要关闭 | 关闭确认、保存草稿 |
| `onWindowMaximize()` | 窗口最大化 | 更新 UI 状态 |
| `onWindowUnmaximize()` | 窗口退出最大化 | 更新 UI 状态 |
| `onWindowMinimize()` | 窗口最小化 | 暂停轮询、降低刷新频率 |
| `onWindowRestore()` | 窗口恢复 | 恢复轮询、刷新数据 |
| `onWindowEnterFullScreen()` | 进入全屏 | 隐藏无关 UI |
| `onWindowLeaveFullScreen()` | 退出全屏 | 恢复 UI |
| `onWindowMove()` | 窗口正在移动 | 通常少用 |
| `onWindowMoved()` | 窗口移动完成 | 保存窗口位置 |
| `onWindowResize()` | 窗口正在缩放 / 缩放后 | 调整布局 |
| `onWindowResized()` | 窗口缩放完成 | 保存窗口尺寸 |
| `onWindowDocked()` | 窗口进入停靠状态 | Windows 停靠状态同步 |
| `onWindowUndocked()` | 窗口离开停靠状态 | Windows 停靠状态同步 |

事件监听示例：

```dart
class QsdmsWindowListener with WindowListener {
  @override
  void onWindowResized() async {
    final bounds = await windowManager.getBounds();
    // 将 bounds 写入本地偏好存储，下一次启动时恢复。
  }

  @override
  void onWindowFocus() {
    // 窗口回到前台时可以刷新必要状态。
  }
}
```

## 12. 事件常量

这些常量是事件名称字符串，通常用于统一事件分发或调试日志。

| 常量 | 对应含义 |
|---|---|
| `kWindowEventBlur` | 窗口失焦 |
| `kWindowEventClose` | 窗口关闭 |
| `kWindowEventDocked` | 窗口停靠 |
| `kWindowEventEnterFullScreen` | 进入全屏 |
| `kWindowEventFocus` | 窗口聚焦 |
| `kWindowEventLeaveFullScreen` | 离开全屏 |
| `kWindowEventMaximize` | 最大化 |
| `kWindowEventMinimize` | 最小化 |
| `kWindowEventMove` | 移动中 |
| `kWindowEventMoved` | 移动完成 |
| `kWindowEventResize` | 缩放中 / 缩放后 |
| `kWindowEventResized` | 缩放完成 |
| `kWindowEventRestore` | 恢复 |
| `kWindowEventUndocked` | 取消停靠 |
| `kWindowEventUnmaximize` | 退出最大化 |

## 13. 枚举说明

### 13.1 TitleBarStyle

用于控制标题栏样式。

| 枚举 | 用途 |
|---|---|
| `TitleBarStyle.normal` | 使用系统默认标题栏 |
| `TitleBarStyle.hidden` | 隐藏标题栏，适合自定义标题栏 |

### 13.2 ResizeEdge

用于 `startResizing()`，表示从哪个边或角开始缩放窗口。

常见含义：

- 左边缘
- 右边缘
- 上边缘
- 下边缘
- 左上角
- 右上角
- 左下角
- 右下角

具体枚举名称以当前版本 API 为准。

### 13.3 DockSide

用于 Windows 的 `dock()`，表示窗口停靠方向。

常见含义：

- 左侧停靠
- 右侧停靠

具体枚举名称以当前版本 API 为准。

## 14. 辅助函数

| API | 作用 | 使用场景 |
|---|---|---|
| `calcWindowPosition(windowSize, alignment)` | 根据窗口尺寸和屏幕对齐方式计算位置 | 自定义居中、贴边、恢复位置 |

如果只是简单居中，优先用 `center()`。如果要计算复杂位置，例如右下角悬浮窗，再考虑 `calcWindowPosition()`。

## 15. 常见业务场景怎么选 API

### 15.1 启动时设置默认尺寸并居中

使用：

- `WindowOptions(size: Size(1440, 810), center: true)`
- `waitUntilReadyToShow()`
- `show()`
- `focus()`

当前项目如果只需要固定默认尺寸，继续用原生 runner 即可。

### 15.2 设置最小窗口尺寸

使用：

- `WindowOptions(minimumSize: Size(...))`
- 或启动后 `setMinimumSize(Size(...))`

适合管理系统，能避免用户把窗口缩得太小导致表格和表单不可用。

### 15.3 关闭前确认

使用：

- `setPreventClose(true)`
- `WindowListener.onWindowClose()`
- 用户确认后 `setPreventClose(false)` + `close()`

适合存在未保存表单、未完成导入、后台同步任务的页面。

### 15.4 记住窗口大小和位置

使用：

- `onWindowMoved()`
- `onWindowResized()`
- `getBounds()`
- 下次启动时 `WindowOptions(size: ...)` 或 `setBounds(...)`

注意：`window_manager` 本身不提供偏好存储，需要配合本地存储方案。

### 15.5 自定义标题栏

使用：

- `setTitleBarStyle(TitleBarStyle.hidden)`
- `DragToMoveArea`
- `WindowCaption`
- `WindowCaptionButton`

注意：这是 UI 和原生窗口交互的组合需求，需要逐平台测试。

### 15.6 最小化到托盘

`window_manager` 可以：

- `hide()`
- `show()`
- `restore()`
- `setSkipTaskbar(true)`

但它不负责系统托盘图标。如果要完整托盘能力，需要配合 `tray_manager` 或 `nativeapi` 等库。

## 16. 平台差异和风险

| 能力 | 差异 |
|---|---|
| `dock()` / `undock()` | 官方标注仅 Windows |
| `grabKeyboard()` / `ungrabKeyboard()` | 官方标注 Linux |
| 自定义标题栏 | macOS / Windows / Linux 体验差异明显 |
| 阴影控制 | Windows 上通常无边框窗口才更明显 |
| 全屏 | macOS 和 Windows 的全屏体验不同 |
| 任务栏 / Dock | `skipTaskbar` 在不同平台表现可能不同 |
| 窗口按钮可见性 | 不同平台的按钮位置和行为不同 |

凡是涉及平台外观或窗口系统行为的功能，都应该至少在目标平台分别验证。

## 17. 不适合用 window_manager 解决的问题

`window_manager` 不适合解决这些问题：

- 多窗口创建和跨窗口通信：优先看 `desktop_multi_window`、`window_manager_plus` 或 `nativeapi`。
- 系统托盘完整能力：需要 `tray_manager` 或 `nativeapi`。
- 原生菜单系统：需要其他菜单库或 `nativeapi`。
- 本地偏好存储：需要 `shared_preferences`、文件存储、数据库或 `nativeapi` 的偏好存储。
- 业务页面布局：应该在 Flutter Widget 层处理。
- 权限、接口、数据库、后端逻辑：与窗口管理无关。

## 18. 对 QSDMS_DESKTOP 的建议

短期建议：

- 默认窗口尺寸、标题隐藏继续使用原生 runner 配置。
- 不为了这两个静态需求引入 `window_manager`。

中期可以引入的条件：

- 需要关闭前确认。
- 需要记住用户窗口大小和位置。
- 需要运行时切换全屏 / 最大化 / 最小化。
- 需要自定义标题栏。
- 需要窗口置顶或隐藏到后台。

如果引入，建议封装一个项目级服务，例如：

```dart
class DesktopWindowService {
  Future<void> initialize() async {
    await windowManager.ensureInitialized();
  }

  Future<void> showDefaultWindow() async {
    const options = WindowOptions(
      size: Size(1440, 810),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
}
```

这样可以避免业务页面到处直接调用 `windowManager`，后续替换为 `nativeapi` 或原生实现也更容易。

## 19. 官方资料

- `window_manager` pub.dev 页面：<https://pub.dev/packages/window_manager>
- `WindowManager` API：<https://pub.dev/documentation/window_manager/latest/window_manager/WindowManager-class.html>
- `WindowOptions` API：<https://pub.dev/documentation/window_manager/latest/window_manager/WindowOptions-class.html>
- `WindowListener` API：<https://pub.dev/documentation/window_manager/latest/window_manager/WindowListener-class.html>
- `window_manager` GitHub 仓库：<https://github.com/leanflutter/window_manager>

