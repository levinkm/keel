import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // Forward keel:// deep links to Flutter via app_links
  override func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    guard let controller = mainFlutterWindow?.contentViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.llfbandit.app_links/messages",
      binaryMessenger: controller.engine.binaryMessenger
    )
    channel.invokeMethod("onAppLink", arguments: url.absoluteString)
  }
}
