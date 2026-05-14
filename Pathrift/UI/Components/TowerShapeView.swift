import SwiftUI

struct TowerShapeView: View {
    let type: TowerType
    var size: CGFloat = 36

    var body: some View {
        Canvas { ctx, sz in
            let cx = sz.width / 2
            let cy = sz.height / 2
            let color = type.swiftUIColor

            switch type {

            case .bolt:
                var p = Path()
                p.move(to: CGPoint(x: cx + 3, y: 4))
                p.addLine(to: CGPoint(x: cx - 3, y: sz.height * 0.46))
                p.addLine(to: CGPoint(x: cx + 2, y: sz.height * 0.46))
                p.addLine(to: CGPoint(x: cx - 3, y: sz.height - 4))
                ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

            case .blast:
                var p = Path()
                let r = sz.width * 0.40
                for i in 0..<8 {
                    let angle = Double(i) * .pi / 4 - .pi / 8
                    let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
                    i == 0 ? p.move(to: pt) : p.addLine(to: pt)
                }
                p.closeSubpath()
                ctx.fill(p, with: .color(color.opacity(0.9)))
                ctx.fill(Path(ellipseIn: CGRect(x: cx-4, y: cy-4, width: 8, height: 8)), with: .color(.white.opacity(0.7)))

            case .frost:
                let r = sz.width * 0.42
                for i in 0..<6 {
                    let angle = Double(i) * .pi / 3
                    var line = Path()
                    line.move(to: CGPoint(x: cx, y: cy))
                    line.addLine(to: CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle)))
                    ctx.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                }
                ctx.fill(Path(ellipseIn: CGRect(x: cx-3, y: cy-3, width: 6, height: 6)), with: .color(color))

            case .pierce:
                var p = Path()
                p.move(to: CGPoint(x: sz.width - 4, y: cy))
                p.addLine(to: CGPoint(x: 4, y: cy - sz.height * 0.28))
                p.addLine(to: CGPoint(x: 4 + sz.width * 0.15, y: cy))
                p.addLine(to: CGPoint(x: 4, y: cy + sz.height * 0.28))
                p.closeSubpath()
                ctx.fill(p, with: .color(color.opacity(0.9)))

            case .core:
                let inset: CGFloat = 5
                ctx.stroke(Path(roundedRect: CGRect(x: inset, y: inset, width: sz.width - 2*inset, height: sz.height - 2*inset), cornerRadius: 3),
                           with: .color(color), style: StrokeStyle(lineWidth: 2.5))
                ctx.fill(Path(ellipseIn: CGRect(x: cx-4, y: cy-4, width: 8, height: 8)), with: .color(color))

            case .inferno:
                for (i, (scale, alpha)) in [(1.0, 0.9), (0.68, 0.55), (0.38, 0.3)].enumerated() {
                    let fh = sz.height * 0.38 * scale
                    let fw = sz.width * 0.27 * scale
                    var flame = Path()
                    flame.move(to: CGPoint(x: cx, y: cy + fh))
                    flame.addCurve(to: CGPoint(x: cx, y: cy - fh * 0.6),
                                   control1: CGPoint(x: cx + fw, y: cy + fh * 0.2),
                                   control2: CGPoint(x: cx + fw * 0.5, y: cy - fh * 0.3))
                    flame.addCurve(to: CGPoint(x: cx, y: cy + fh),
                                   control1: CGPoint(x: cx - fw * 0.5, y: cy - fh * 0.3),
                                   control2: CGPoint(x: cx - fw, y: cy + fh * 0.2))
                    ctx.fill(flame, with: .color(color.opacity(alpha)))
                    _ = i
                }

            case .tesla:
                ctx.stroke(Path(ellipseIn: CGRect(x: 4, y: 4, width: sz.width-8, height: sz.height-8)),
                           with: .color(color.opacity(0.45)), style: StrokeStyle(lineWidth: 1.5))
                var bolt = Path()
                bolt.move(to: CGPoint(x: cx + 3, y: 5))
                bolt.addLine(to: CGPoint(x: cx - 2, y: cy))
                bolt.addLine(to: CGPoint(x: cx + 2, y: cy))
                bolt.addLine(to: CGPoint(x: cx - 3, y: sz.height - 5))
                ctx.stroke(bolt, with: .color(color), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

            case .nova:
                let r1 = sz.width * 0.43
                let r2 = sz.width * 0.17
                var star = Path()
                for i in 0..<8 {
                    let angle = Double(i) * .pi / 4 - .pi / 2
                    let r = i % 2 == 0 ? r1 : r2
                    let pt = CGPoint(x: cx + r * cos(angle), y: cy + r * sin(angle))
                    i == 0 ? star.move(to: pt) : star.addLine(to: pt)
                }
                star.closeSubpath()
                ctx.fill(star, with: .color(color.opacity(0.9)))

            case .sniper:
                ctx.fill(Path(roundedRect: CGRect(x: 6, y: cy-4, width: sz.width-10, height: 8), cornerRadius: 2),
                         with: .color(color.opacity(0.85)))
                ctx.stroke(Path(ellipseIn: CGRect(x: 3, y: cy-10, width: 20, height: 20)),
                           with: .color(color), style: StrokeStyle(lineWidth: 1.5))
                let crossH = Path { p in p.move(to: CGPoint(x: 3, y: cy)); p.addLine(to: CGPoint(x: 23, y: cy)) }
                let crossV = Path { p in p.move(to: CGPoint(x: 13, y: cy-10)); p.addLine(to: CGPoint(x: 13, y: cy+10)) }
                ctx.stroke(crossH, with: .color(color.opacity(0.5)), style: StrokeStyle(lineWidth: 0.8))
                ctx.stroke(crossV, with: .color(color.opacity(0.5)), style: StrokeStyle(lineWidth: 0.8))

            case .artillery:
                ctx.fill(Path(ellipseIn: CGRect(x: cx-13, y: cy-13, width: 26, height: 26)), with: .color(color.opacity(0.8)))
                ctx.fill(Path(roundedRect: CGRect(x: cx+1, y: cy-4, width: sz.width * 0.32, height: 8), cornerRadius: 3),
                         with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}
