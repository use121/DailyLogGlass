import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @AppStorage(AppKeys.themeMode) private var themeRaw: String = ThemeMode.dark.rawValue
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]

    @State private var shareURL: URL?
    @State private var rendering: Bool = false

    private var theme: ThemeMode {
        ThemeMode(rawValue: themeRaw) ?? .dark
    }

    private var year: Int {
        Calendar.current.component(.year, from: .now)
    }

    private var yearEntries: [Entry] {
        entries.filter { Calendar.current.component(.year, from: $0.date) == year }
    }

    private var longestStreak: Int {
        let cal = Calendar.current
        let sorted = yearEntries.map { cal.startOfDay(for: $0.date) }.sorted()
        guard !sorted.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for i in 1..<sorted.count {
            if let next = cal.date(byAdding: .day, value: 1, to: sorted[i - 1]),
               next == sorted[i] {
                current += 1
                best = max(best, current)
            } else if sorted[i] != sorted[i - 1] {
                current = 1
            }
        }
        return best
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                themeCard
                shareCard
                aboutCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .task { renderCard() }
    }

    // MARK: - 主题

    private var themeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("外观")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(ThemeMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            themeRaw = mode.rawValue
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 18, weight: .medium))
                            Text(mode.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(theme == mode ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        theme == mode ? .regular.interactive() : .regular,
                        in: .rect(cornerRadius: 18)
                    )
                }
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 26)
    }

    // MARK: - 年度卡片

    private var shareCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("年度回顾")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text("把 \(year) 年所有的记录，压成一张可以分享的图。")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(.secondary)

            if let shareURL {
                ShareLink(item: shareURL) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享 \(year) 年度卡片")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                }
                .buttonStyle(.glassProminent)
                .tint(.primary)
                .foregroundStyle(Color(uiColor: .systemBackground))
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                    Text(rendering ? "正在生成…" : "还没有记录")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 26)
    }

    // MARK: - 关于

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DailyLog Glass")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)

            Text("数据保存在本机，不上传任何服务器。卸载 App 会一并删除。")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 26)
    }

    // MARK: - 渲染

    private func renderCard() {
        guard !yearEntries.isEmpty else { return }
        rendering = true

        let card = ShareCardView(
            year: year,
            entries: yearEntries,
            longestStreak: longestStreak
        )

        let renderer = ImageRenderer(content: card)
        renderer.scale = 3

        guard let image = renderer.uiImage,
              let data = image.pngData() else {
            rendering = false
            return
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("DailyLog-\(year).png")

        do {
            try data.write(to: url, options: .atomic)
            shareURL = url
        } catch {
            shareURL = nil
        }

        rendering = false
    }
}
