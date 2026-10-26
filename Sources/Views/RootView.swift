import SwiftUI

struct RootView: View {
    @AppStorage(AppKeys.themeMode) private var themeRaw: String = ThemeMode.dark.rawValue
    @State private var selection: Int = 0

    private var theme: ThemeMode {
        ThemeMode(rawValue: themeRaw) ?? .dark
    }

    var body: some View {
        ZStack {
            GlassBackground()

            TabView(selection: $selection) {
                TodayView()
                    .tag(0)
                    .tabItem { Label("今日", systemImage: "sun.max.fill") }

                TimelinePage()
                    .tag(1)
                    .tabItem { Label("回顾", systemImage: "square.stack.3d.up.fill") }

                StatsView()
                    .tag(2)
                    .tabItem { Label("统计", systemImage: "chart.bar.fill") }

                SettingsView()
                    .tag(3)
                    .tabItem { Label("设置", systemImage: "gearshape.fill") }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .tint(.primary)
        }
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    RootView()
        .modelContainer(for: Entry.self, inMemory: true)
}
