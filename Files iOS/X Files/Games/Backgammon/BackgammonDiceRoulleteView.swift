import SwiftUI
import Foundation

struct BackgammonDiceRouletteView: View {

    let colors: BackgammonColorAssignment
    let onContinue: (BackgammonStartDiceResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var spinning = false
    @State private var rotation: Double = 0

    @State private var blackDie: Int = 1
    @State private var whiteDie: Int = 1

    @State private var hasResult = false
    @State private var isTie = false
    @State private var tieCount = 0

    // MARK: - UI

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Text("Ruleta de inicio")
                    .font(.title.bold())
                    .padding(.top, 6)

                Text("Cada jugador tira 1 dado. El mayor empieza (mayor + menor).")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)

                wheel

                HStack(spacing: 14) {
                    playerDieCard(
                        name: colors.blackPlayer,
                        piece: "NEGRAS",
                        die: blackDie,
                        dark: false
                    )

                    Text("VS")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    playerDieCard(
                        name: colors.whitePlayer,
                        piece: "BLANCAS",
                        die: whiteDie,
                        dark: true
                    )
                }
                .padding(.top, 6)

                // Mensaje resumen (cuando ya hay resultado y NO es empate)
                if hasResult && !isTie {
                    summary
                }

                // Mensaje empate
                if hasResult && isTie {
                    Text("Empate — repite la tirada  x\(tieCount + 1)")
                        .font(.footnote.bold())
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.yellow.opacity(0.25))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                }

                Spacer(minLength: 8)

                // ✅ Girar SOLO si no hay resultado aún, o si hay empate
                if !hasResult || isTie {
                    Button {
                        spinOnce()
                    } label: {
                        Text(spinning ? "Girando..." : (isTie ? "Girar de nuevo" : "Girar"))
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(spinning)
                    .padding(.horizontal, 16)
                }

                // ✅ Continuar SOLO cuando ya hay resultado y NO hay empate
                if hasResult && !isTie {
                    Button {
                        onContinue(makeResult())
                    } label: {
                        Text("Continuar")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
        }
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var wheel: some View {
        ZStack {
            BGStartDiceWheel(rotation: rotation)

            BGStartDicePointer()
                .offset(y: -140)

            // Botón central “Listo”
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 90, height: 90)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 8)

                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(.black.opacity(0.85))

                    Text("Listo")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(height: 300)
        .padding(.top, 6)
    }

    private var summary: some View {
        let starterName = (blackDie > whiteDie) ? colors.blackPlayer : colors.whitePlayer
        let starterPiece = (blackDie > whiteDie) ? "NEGRAS" : "BLANCAS"
        let major = max(blackDie, whiteDie)
        let minor = min(blackDie, whiteDie)

        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text("Empieza: \(starterName)")
                    .font(.headline)

                Text(starterPiece)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(starterPiece == "NEGRAS" ? Color.black.opacity(0.85) : Color.gray.opacity(0.18))
                    .foregroundColor(starterPiece == "NEGRAS" ? .white : .primary)
                    .cornerRadius(10)
            }

            Text("Primer tiro: \(major) + \(minor)")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func playerDieCard(name: String, piece: String, die: Int, dark: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(name)
                .font(.headline.bold())
                .foregroundColor(dark ? .white : .primary)

            Text(piece)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    dark
                    ? (piece == "NEGRAS" ? Color.black.opacity(0.85) : Color.white.opacity(0.12))
                    : (piece == "NEGRAS" ? Color.black.opacity(0.85) : Color.gray.opacity(0.18))
                )
                .foregroundColor(dark ? .white : (piece == "NEGRAS" ? .white : .primary))
                .cornerRadius(10)

            Text("Dado: \(die)")
                .font(.footnote)
                .foregroundColor(dark ? .white.opacity(0.85) : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(dark ? Color.black.opacity(0.85) : Color.gray.opacity(0.18))
        .cornerRadius(16)
    }

    private func spinOnce() {
        guard !spinning else { return }
        spinning = true

        // reseteo “resultado final” antes de tirar
        hasResult = false
        isTie = false

        let extraTurns = Double(Int.random(in: 3...6)) * 360.0
        let landing = Double(Int.random(in: 0...359))

        withAnimation(.easeOut(duration: 0.95)) {
            rotation += extraTurns + landing
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            blackDie = Int.random(in: 1...6)
            whiteDie = Int.random(in: 1...6)

            hasResult = true
            isTie = (blackDie == whiteDie)

            if isTie {
                tieCount += 1
            }

            spinning = false
        }
    }

    private func makeResult() -> BackgammonStartDiceResult {
        // Convención del proyecto actual: player1 = NEGRAS, player2 = BLANCAS
        let starts: BGSide = (blackDie > whiteDie) ? .player1 : .player2
        return BackgammonStartDiceResult(die1: blackDie, die2: whiteDie, starts: starts)
    }
}

// MARK: - Wheel (1..6)

private struct BGStartDiceWheel: View {
    let rotation: Double

    var body: some View {
        ZStack {
            ForEach(1...6, id: \.self) { v in
                BGStartDiceSlice(
                    index: v - 1,
                    total: 6,
                    label: "\(v)"
                )
            }
        }
        .frame(width: 280, height: 280)
        .rotationEffect(.degrees(rotation))
        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 10)
    }
}

private struct BGStartDiceSlice: View {
    let index: Int
    let total: Int
    let label: String

    var body: some View {
        let start = Angle(degrees: Double(index) * (360.0 / Double(total)) - 90.0)
        let end = Angle(degrees: Double(index + 1) * (360.0 / Double(total)) - 90.0)
        let fill = (index % 2 == 0) ? Color.gray.opacity(0.22) : Color.gray.opacity(0.42)

        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: 140, y: 140))
                p.addArc(
                    center: CGPoint(x: 140, y: 140),
                    radius: 140,
                    startAngle: start,
                    endAngle: end,
                    clockwise: false
                )
                p.closeSubpath()
            }
            .fill(fill)

            Text(label)
                .font(.headline.bold())
                .foregroundColor(.black.opacity(0.8))
                .position(labelPosition(startAngle: start, endAngle: end))
        }
    }

    private func labelPosition(startAngle: Angle, endAngle: Angle) -> CGPoint {
        let mid = (startAngle.radians + endAngle.radians) / 2.0
        let radius: CGFloat = 105
        let cx: CGFloat = 140
        let cy: CGFloat = 140

        // Darwin.cos/sin para evitar “Ambiguous use of cos”
        let x = cx + radius * CGFloat(Darwin.cos(mid))
        let y = cy + radius * CGFloat(Darwin.sin(mid))
        return CGPoint(x: x, y: y)
    }
}

private struct BGStartDicePointer: View {
    var body: some View {
        BGStartDiceTriangle()
            .fill(Color.orange.opacity(0.95))
            .frame(width: 20, height: 16)
            .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 4)
    }
}

private struct BGStartDiceTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
