import SwiftUI
import Foundation

struct BackgammonColorRouletteView: View {

    let player1Name: String
    let player2Name: String
    let onContinue: (BackgammonColorAssignment) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var spinning = false
    @State private var rotation: Double = 0

    // ✅ CLAVE UX: nil = todavía no hay asignación (NO pre-asigna)
    @State private var p1IsBlack: Bool? = nil

    private var p1Upper: String { sanitizeToUpper(player1Name, fallback: "JUGADOR 1") }
    private var p2Upper: String { sanitizeToUpper(player2Name, fallback: "JUGADOR 2") }

    private var hasResult: Bool { p1IsBlack != nil }

    private var assignment: BackgammonColorAssignment? {
        guard let p1IsBlack else { return nil }

        let blackPlayer = p1IsBlack ? p1Upper : p2Upper
        let whitePlayer = p1IsBlack ? p2Upper : p1Upper

        let blackSide: BGSide = p1IsBlack ? .player1 : .player2
        let whiteSide: BGSide = p1IsBlack ? .player2 : .player1

        return BackgammonColorAssignment(
            blackSide: blackSide,
            whiteSide: whiteSide,
            blackPlayer: blackPlayer,
            whitePlayer: whitePlayer
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Text("Ruleta de colores")
                    .font(.title.bold())
                    .padding(.top, 8)

                Text("Asigna BLANCAS y NEGRAS")
                    .font(.footnote)
                    .foregroundColor(.secondary)

                wheel

                VStack(spacing: 12) {
                    playerCard(
                        name: p1Upper,
                        piece: pieceTextForP1,
                        dark: (p1IsBlack == true)
                    )

                    playerCard(
                        name: p2Upper,
                        piece: pieceTextForP2,
                        dark: (p1IsBlack == false && p1IsBlack != nil)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                Spacer(minLength: 10)

                // ✅ Botón Girar SOLO antes de tener resultado
                if !hasResult {
                    Button {
                        spinOnce()
                    } label: {
                        Text(spinning ? "Girando..." : "Girar")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(spinning)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }

                // ✅ Botón Continuar SOLO cuando ya hay resultado
                if hasResult {
                    Button {
                        if let a = assignment {
                            onContinue(a)
                        }
                    } label: {
                        Text("Continuar")
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Button {
                        resetSpin()
                        spinOnce()
                    } label: {
                        Text("Repetir giro")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cerrar") { dismiss() }
            }
        }
    }

    // MARK: - Wheel

    private var wheel: some View {
        ZStack {
            ZStack {
                BGHalfPie(color: Color.gray.opacity(0.18))
                BGHalfPie(color: Color.black.opacity(0.88))
                    .rotationEffect(.degrees(180))
            }
            .rotationEffect(.degrees(rotation))
            .animation(.easeOut(duration: 1.10), value: rotation)

            // Textos decorativos del wheel
            ZStack {
                Text("BLANCAS")
                    .font(.headline.bold())
                    .rotationEffect(.degrees(-25))
                    .offset(x: -78, y: 45)
                    .foregroundColor(.black.opacity(0.75))

                Text("NEGRAS")
                    .font(.headline.bold())
                    .rotationEffect(.degrees(25))
                    .offset(x: 78, y: 45)
                    .foregroundColor(.white.opacity(0.92))
            }
            .rotationEffect(.degrees(rotation))
            .animation(.easeOut(duration: 1.10), value: rotation)

            // Centro
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 92, height: 92)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 8)

                VStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.title3)
                        .foregroundColor(.black.opacity(0.85))
                    Text("Listo")
                        .font(.headline)
                        .foregroundColor(.black.opacity(0.85))
                }
            }

            // Puntero
            BGTrianglePointer()
                .fill(Color.orange.opacity(0.95))
                .frame(width: 22, height: 16)
                .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 4)
                .offset(y: -170)
        }
        .frame(width: 340, height: 340)
        .padding(.top, 8)
    }

    // MARK: - Derived UI

    private var pieceTextForP1: String {
        guard let p1IsBlack else { return "—" }
        return p1IsBlack ? "NEGRAS" : "BLANCAS"
    }

    private var pieceTextForP2: String {
        guard let p1IsBlack else { return "—" }
        return p1IsBlack ? "BLANCAS" : "NEGRAS"
    }

    private func playerCard(name: String, piece: String, dark: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline.bold())
                .foregroundColor(dark ? .white : .primary)

            Text(piece)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(dark ? Color.black.opacity(0.88) : Color.gray.opacity(0.18))
                .foregroundColor(dark ? .white : .primary)
                .cornerRadius(10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(dark ? Color.black.opacity(0.88) : Color.gray.opacity(0.18))
        .cornerRadius(14)
    }

    // MARK: - Actions

    private func spinOnce() {
        guard !spinning else { return }
        spinning = true
        p1IsBlack = nil

        let extraTurns = Double(Int.random(in: 3...6)) * 360.0
        let landing = Double(Int.random(in: 0...359))

        withAnimation(.easeOut(duration: 1.10)) {
            rotation += extraTurns + landing
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.10) {
            p1IsBlack = Bool.random()
            spinning = false
        }
    }

    private func resetSpin() {
        p1IsBlack = nil
        spinning = false
    }

    // MARK: - Helpers

    private func sanitizeToUpper(_ s: String, fallback: String) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? fallback : t.uppercased()
    }
}

// MARK: - Local shapes (nombres únicos para evitar “redeclaration”)

private struct BGHalfPie: View {
    let color: Color
    var body: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2
            Path { p in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                p.move(to: center)
                p.addArc(center: center, radius: r, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                p.closeSubpath()
            }
            .fill(color)
        }
    }
}

private struct BGTrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
