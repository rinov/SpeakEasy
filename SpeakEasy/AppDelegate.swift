import Foundation
import UIKit
import AWSPolly

class AppDelegate: NSObject, UIApplicationDelegate {

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      let accessKey = CredentialManager.shared.value(for: .awsAccessKey)
      let secretKey = CredentialManager.shared.value(for: .awsSecretKey)
      let credentialsProvider = AWSStaticCredentialsProvider(accessKey: accessKey, secretKey: secretKey)
 
      // AWS Pollyを利用するための設定
      // NOTE: 応答レスポンスの速度向上のため違いリージョンを選択すること e.g. APNortheast1
      AWSServiceManager.default().defaultServiceConfiguration = AWSServiceConfiguration(region: .APNortheast1, credentialsProvider: credentialsProvider)

      return true
  }
}
