import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let customTitleBarHeight: CGFloat = 40

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()

    installTrafficLightButtonCentering()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  private func installTrafficLightButtonCentering() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(centerTrafficLightButtons),
      name: NSWindow.didResizeNotification,
      object: self)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(centerTrafficLightButtons),
      name: NSWindow.didBecomeKeyNotification,
      object: self)

    // window_manager 会在 Dart 启动流程里再应用隐藏标题栏样式，所以这里先
    // 立即校正一次，再等下一轮布局后补一次，避免原生按钮回到系统默认位置。
    DispatchQueue.main.async { [weak self] in
      self?.centerTrafficLightButtons()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      self?.centerTrafficLightButtons()
    }
  }

  @objc private func centerTrafficLightButtons() {
    guard let closeButton = standardWindowButton(.closeButton),
          let minimizeButton = standardWindowButton(.miniaturizeButton),
          let zoomButton = standardWindowButton(.zoomButton),
          let trafficLightButtonContainer = closeButton.superview,
          let titleBarView = trafficLightButtonContainer.superview
    else {
      return
    }

    titleBarView.layoutSubtreeIfNeeded()

    // macOS 原生标题栏视图通常只有 32px，高于/低于 Flutter 40px 窗口栏时
    // 都要按 40px 目标区域重新定位；这里允许负值，才能把按钮组下移到
    // Flutter 窗口栏中心。
    let titleBarBottomY = titleBarView.bounds.height - customTitleBarHeight
    let containerOffsetY = max(
      0,
      (customTitleBarHeight - trafficLightButtonContainer.frame.height) / 2)
    let centeredY = titleBarBottomY + containerOffsetY

    trafficLightButtonContainer.setFrameOrigin(
      NSPoint(x: trafficLightButtonContainer.frame.origin.x, y: centeredY))

    let buttonOffsetY = max(
      0,
      (trafficLightButtonContainer.bounds.height - closeButton.frame.height) / 2)

    closeButton.setFrameOrigin(NSPoint(x: closeButton.frame.origin.x, y: buttonOffsetY))
    minimizeButton.setFrameOrigin(NSPoint(x: minimizeButton.frame.origin.x, y: buttonOffsetY))
    zoomButton.setFrameOrigin(NSPoint(x: zoomButton.frame.origin.x, y: buttonOffsetY))

    trafficLightButtonContainer.needsLayout = true
    titleBarView.needsLayout = true
  }
}
