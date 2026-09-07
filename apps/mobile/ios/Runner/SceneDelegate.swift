import Flutter
import UIKit
import FirebaseAuth

class SceneDelegate: FlutterSceneDelegate {
  // Firebase Phone Auth reCAPTCHA / custom-scheme callbacks arrive here with UIScene.
  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    for context in URLContexts {
      if Auth.auth().canHandle(context.url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }

  override func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if let url = userActivity.webpageURL, Auth.auth().canHandle(url) {
      return
    }
    super.scene(scene, continue: userActivity)
  }
}
