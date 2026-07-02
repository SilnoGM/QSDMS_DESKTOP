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
          let titleBarView = closeButton.superview
    else {
      return
    }

    let buttonY = (customTitleBarHeight - closeButton.frame.height) / 2
    let centeredY = max(0, buttonY)

    closeButton.setFrameOrigin(NSPoint(x: closeButton.frame.origin.x, y: centeredY))
    minimizeButton.setFrameOrigin(NSPoint(x: minimizeButton.frame.origin.x, y: centeredY))
    zoomButton.setFrameOrigin(NSPoint(x: zoomButton.frame.origin.x, y: centeredY))

    titleBarView.needsLayout = true
  }
}
