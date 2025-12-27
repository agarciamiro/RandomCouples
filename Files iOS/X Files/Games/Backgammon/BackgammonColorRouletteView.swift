import SwiftUI
import UIKit

struct BackgammonColorRouletteView: View {

    let player1Name: String
    let player2Name: String
    let onContinue: (BackgammonColorAssignment) -> Void

    @State private var assigned: BackgammonColorAssignment? = nil
    @State private var spinning: Bool = false
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 14) {

            VStack(spacing: 6) {
                Text("Ruleta de colores")
                    .font(.title2.bold())
                Text("Asigna BLANCAS y NEGRAS")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)

            ZStack {
                RuletaWheel(
                    leftTitle: "BLANCAS",
                    rightTitle: "NEGRAS",
                    leftColor: Color.gray.opacity(0.22),
                    rightColor: Color.black.opacity(0.90),
                    rotation: rotation
                )
                .frame(width: 270, height: 270)

                PointerTriangle()
                    .fill(Color.orange.opacity(0.95))
                    .frame(width: 28, height: 18)
                    .offset(y: -146)

                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Button {
                            guard assigned == nil else { return }
                            spinAndAssign()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: (assigned == nil) ? "dice" : "checkmark.seal.fill")
                                    .font(.title2.weight(.semibold))
                                Text((assigned == nil) ? "Girar" : "Listo")
                                    .font(.headline)
                            }
                            .foregroundColor(.primary)
                        }
                        .disabled(assigned != nil || spinning)
                    )
                    .shadow(radius: 6, x: 0, y: 3)
            }
            .padding(.top, 6)

            if let a = assigned {
                VStack(spacing: 10) {

                    // NEGRAS -> tarjeta gris clara, texto negro bold
                    playerCard(
                        name: a.blackPlayer.uppercased(),
                        label: "NEGRAS",
                        background: Color(.systemGray5),
                        foreground: .black
                    )

                    // BLANCAS -> tarjeta negra, texto blanco bold
                    playerCard(
                        name: a.whitePlayer.uppercased(),
                        label: "BLANCAS",
                        background: Color.black.opacity(0.85),
                        foreground: .white
                    )
                }
                .padding(.top, 6)
                .padding(.horizontal, 16)
            } else {
                Text("Toca “Girar” para asignar colores.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }

            Spacer()

            Button {
                if let a = assigned { onContinue(a) }
            } label: {
                Text("Continuar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
            .disabled(assigned == nil)
        }
    }

    private func playerCard(name: String, label: String, background: Color, foreground: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.headline.bold())
            Text(label)
                .font(.title3.bold())
        }
        .foregroundColor(foreground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(background)
        )
    }

    private func spinAndAssign() {
        spinning = true

        let p1IsWhite = Bool.random()
        let a = BackgammonColorAssignment(
            whitePlayer: p1IsWhite ? player1Name : player2Name,
            blackPlayer: p1IsWhite ? player2Name : player1Name
        )

        let extra = Double.random(in: 40...320)
        let target = rotation + 720 + extra

        withAnimation(.easeOut(duration: 1.2)) {
            rotation = target
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            assigned = a
            spinning = false
        }
    }
}

// MARK: - Helpers
private struct RuletaWheel: View {
    let leftTitle: String
    let rightTitle: String
    let leftColor: Color
    let rightColor: Color
    let rotation: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear)
                .overlay(RuletaHalf(color: leftColor).rotationEffect(.degrees(180)))
                .overlay(RuletaHalf(color: rightColor))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 1))
                .shadow(radius: 10, x: 0, y: 6)

            Text(leftTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black.opacity(0.75))
                .rotationEffect(.degrees(-90))
                .offset(x: -94)

            Text(rightTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.92))
                .rotationEffect(.degrees(90))
                .offset(x: 94)
        }
        .rotationEffect(.degrees(rotation))
    }
}

private struct RuletaHalf: View {
    let color: Color
    var body: some View {
        GeometryReader { geo in
            Path { p in
                let rect = geo.frame(in: .local)
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let radius = min(rect.width, rect.height) / 2
                p.move(to: center)
                p.addArc(center: center, radius: radius, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                p.closeSubpath()
            }
            .fill(color)
        }
    }
}

private struct PointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
