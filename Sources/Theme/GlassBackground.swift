import SwiftUI

/// 缓慢流动的网格渐变，作为液态玻璃的背景层。深浅色各一套配色。
struct GlassBackground: View {
    @Environment(\.colorScheme) private var scheme

    private var colors: [Color] {
        if scheme == .dark {
            return [
                Color(red: 0.08, green: 0.07, blue: 0.18),
                Color(red: 0.24, green: 0.11, blue: 0.34),
                Color(red: 0.06, green: 0.13, blue: 0.28),

                Color(red: 0.30, green: 0.09, blue: 0.26),
                Color(red: 0.13, green: 0.22, blue: 0.46),
                Color(red: 0.09, green: 0.09, blue: 0.24),

                Color(red: 0.05, green: 0.08, blue: 0.20),
                Color(red: 0.17, green: 0.11, blue: 0.33),
                Color(red: 0.07, green: 0.10, blue: 0.22)
            ]
        } else {
            return [
                Color(red: 0.94, green: 0.95, blue: 1.00),
                Color(red: 0.88, green: 0.88, blue: 0.99),
                Color(red: 0.96, green: 0.91, blue: 0.97),

                Color(red: 0.87, green: 0.95, blue: 1.00),
                Color(red: 0.99, green: 0.92, blue: 0.90),
                Color(red: 0.90, green: 0.92, blue: 1.00),

                Color(red: 0.95, green: 0.97, blue: 1.00),
                Color(red: 0.93, green: 0.89, blue: 0.98),
                Color(red: 0.94, green: 0.96, blue: 1.00)
            ]
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate)

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    SIMD2<Float>(0.0, 0.0),
                    SIMD2<Float>(0.5, 0.0),
                    SIMD2<Float>(1.0, 0.0),

                    SIMD2<Float>(0.0, 0.5),
                    SIMD2<Float>(0.5 + 0.16 * sin(t * 0.31), 0.5 + 0.14 * cos(t * 0.24)),
                    SIMD2<Float>(1.0, 0.5),

                    SIMD2<Float>(0.0, 1.0),
                    SIMD2<Float>(0.5 + 0.10 * cos(t * 0.19), 1.0),
                    SIMD2<Float>(1.0, 1.0)
                ],
                colors: colors
            )
        }
        .ignoresSafeArea()
    }
}

/// 玻璃卡片通用修饰：圆角玻璃 + 渐变描边，让边缘更立体。
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 26
    var tint: Color = .clear

    func body(content: Content) -> some View {
        content
            .glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.34), .white.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
                    .allowsHitTesting(false)
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 26, tint: Color = .clear) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius, tint: tint))
    }
}
