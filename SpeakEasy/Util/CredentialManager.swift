import Foundation

final class CredentialManager {
    static let shared = CredentialManager()

    private lazy var plist: [String: Any]? = {
        guard let plistPath = Bundle.main.path(forResource: "credential", ofType: "plist"),
              let plistXML = FileManager.default.contents(atPath: plistPath) else {
               print("Error: Failed to read plist.")
               return nil
           }

           do {
               let plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: nil)
               guard let plistDictionary = plistData as? [String: Any] else {
                   print("Error: Failed to cast plist values to dictionary.")
                   return nil
               }
               return plistDictionary
           } catch {
               print("Error: \(error.localizedDescription)")
               return nil
           }
    }()

    private init() {}

    func value(for key: CredentialKey) -> String {
        return plist?[key.rawValue] as? String ?? ""
    }
}

enum CredentialKey: String {
    case openAiKey = "OPENAI_API_KEY"
    case awsAccessKey = "AWS_ACCESS_KEY"
    case awsSecretKey = "AWS_SECRET_KEY"
    
}
