import SwiftUI
import ShikiTokenSDK

@main
/// Demo app entry point. Creates a shared ShikiClient and presents HomeScreen.
struct SyntaxHighlightApp: App {
    private let client = ShikiClient()

    var body: some Scene {
        WindowGroup {
            HomeScreen(client: client)
        }
    }
}
