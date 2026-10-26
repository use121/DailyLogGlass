import SwiftUI
import SwiftData

@main
struct DailyLogApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Entry.self)
    }
}
