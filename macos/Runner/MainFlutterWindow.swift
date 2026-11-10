import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Initial window size and minimum size
    let screen = NSScreen.main ?? NSScreen.screens[0]
    let screenFrame = screen.visibleFrame
    let w: CGFloat = min(1280, screenFrame.width * 0.85)
    let h: CGFloat = min(800, screenFrame.height * 0.85)
    let x = screenFrame.midX - w / 2
    let y = screenFrame.midY - h / 2
    self.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
    self.minSize = NSSize(width: 900, height: 600)

    // Transparent title bar — Flutter owns the full window
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
