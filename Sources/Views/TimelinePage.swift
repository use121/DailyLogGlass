import SwiftUI
import SwiftData
import UIKit

struct TimelinePage: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]

    var body: some View {
        ScrollView {
            if entries.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(entries) { entry in
                        EntryRow(entry: entry)
                            .contextMenu {
                                Button {
                                    copy(entry)
                                } label: {
                                    Label("复制文字", systemImage: "doc.on.doc")
                                }
                                Button(role: .destructive) {
                                    delete(entry)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .scrollIndicators(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tertiary)
            Text("还没有记录")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            Text("去「今日」写下第一条吧")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 140)
    }

    private func delete(_ entry: Entry) {
        withAnimation {
            context.delete(entry)
            try? context.save()
        }
    }

    private func copy(_ entry: Entry) {
        var parts = [entry.date.formatted(.dateTime.year().month().day())]
        if !entry.title.isEmpty { parts.append(entry.title) }
        if !entry.note.isEmpty { parts.append(entry.note) }
        UIPasteboard.general.string = parts.joined(separator: "\n")
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

struct EntryRow: View {
    let entry: Entry

    private var mood: Mood { Mood.mood(entry.moodIndex) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text(entry.date.formatted(.dateTime.day()))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(entry.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 44)

            Rectangle()
                .fill(mood.tint.opacity(0.75))
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(mood.emoji)
                        .font(.system(size: 15))
                    Text(entry.title.isEmpty ? "无标题" : entry.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                if let image = entry.uiImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 96)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .glassCard(cornerRadius: 24)
    }
}
