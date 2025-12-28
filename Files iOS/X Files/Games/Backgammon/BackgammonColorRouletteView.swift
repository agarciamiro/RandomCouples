import SwiftUI

struct BackgammonColorRouletteView: View {

    let player1Name: String
    let player2Name: String

    /// Devuelve el assignment al padre
    let onContinue: (BackgammonColorAssignment) -> Void

    @State private var spinning: Bool = false
    @State private var rotation: Double = 0
    @State private var hasResult: Bool = false

    // nil = aún no se asignó nada (evita “pre-asignación”)
    @State private var p1IsBlack: Bool? = nil

    // MARK: - Derived

    private var assignment: BackgammonColorAssignment? {
        guard let p1IsBlack else { return nil }

        let p1 = player1Name.uppercased()
        let p2 = player2Name.uppercased()

        let blackPlayer = p1IsBlack ? p1 : p2
        let whitePlayer = p1IsBlack ? p2 : p1

        // Convención: player1 / player2 según el nombre que quedó “negro/blanco”
        // OJO: usamos BGSide (tu enum) para poder amarrar tablero/turnos después.
        let blackSide: BGSide = p1IsBlack ? .player1 : .player2
        let whiteSide: BGSide = p1IsBlack ? .player2 : .player1

        // IMPORTANTE: el init de BackgammonColorAssignment en tu proyecto
        // (por tus errores previos) espera labels en este orden:
        // blackSide, whiteSide, blackPlayer, whitePlayer
        return BackgammonColorAssignment(
            blackSide: blackSide,
            whiteSide: whiteSide,
            blackPlayer: blackPlayer,
            whitePlayer: whitePlayer
        )
    }

    var body: some View {
        VStack(spacing: 16) {

            Text("Ruleta de colores")
                .font(.largeTitle.bold())
                .padding(.top, 8)

            Text("Asigna BLANCAS y NEGRAS")
                .font(.footnote)
                .foregroundColor(.secondary)

            wheel
                .padding(.top, 8)

            VStack(spacing: 12) {
                playerCard(name: player1Name.uppercased(),
                           piece: hasResult ? (p1IsBlack == true ? "NEGRAS" : "BLANCAS") : "",
                           dark: hasResult ? (p1IsBlack == true) : false)

                playerCard(name: player2Name.uppercased(),
                           piece: hasResult ? (p1IsBlack == true ? "BLANCAS" : "NEGRAS") : "",
                           dark: hasResult ? (p1IsBlack != true) : false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 2)

            Spacer()

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
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
                .disabled(spinning)
            } else {
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

                Button {
                    resetSpin()
                } label: {
                    Text("Repetir giro")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 6)
                }
                .padding(.bottom, 18)
            }
        }
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Wheel UI

    private var wheel: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle().stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 18, x: 0, y: 10)

            // Mitad blanca / mitad negra
            PieHalf(color: .white)
                .rotationEffect(.degrees(0))

            PieHalf(color: .black.opacity(0.92))
                .rotationEffect(.degrees(180))

            // Labels
            Text("BLANCAS")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.75))
                .rotationEffect(.degrees(-155))
                .offset(x: -70, y: 36)

            Text("NEGRAS")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white.opacity(0.92))
                .rotationEffect(.degrees(25))
                .offset(x: 76, y: -32)

            // Centro
            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 130, height: 130)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)

            VStack(spacing: 6) {
                Image(systemName: "seal.fill")
                    .font(.title3)
                    .foregroundColor(.black.opacity(0.85))
                Text("Listo")
                    .font(.headline)
                    .foregroundColor(.black.opacity(0.85))
            }

            // Puntero
            BGTrianglePointer()
                .fill(Color.orange.opacity(0.95))
                .frame(width: 20, height: 16)
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 4)
                .offset(y: -170)
        }
        .frame(width: 340, height: 340)
        .rotationEffect(.degrees(rotation))
        .animation(.easeOut(duration: 1.3), value: rotation)
    }

    // MARK: - Actions

    private func spinOnce() {
        guard !spinning else { return }
        spinning = true

        // random assignment
        let p1Black = Bool.random()
        p1IsBlack = p1Black

        // random rotation (con vueltas)
        let turns = Double(Int.random(in: 3...6)) * 360.0
        let offset = Double(Int.random(in: 0...359))
        rotation += turns + offset

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.35) {
            spinning = false
            hasResult = true
        }
    }

    private func resetSpin() {
        hasResult = false
        p1IsBlack = nil
    }

    // MARK: - Cards

    private func playerCard(name: String, piece: String, dark: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.headline.bold())
                .foregroundColor(dark ? .white : .primary)

            if !piece.isEmpty {
                Text(piece)
                    .font(.title3.bold())
                    .foregroundColor(dark ? .white : .primary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dark ? Color.black.opacity(0.88) : Color.gray.opacity(0.18))
        .cornerRadius(14)
    }
}

// MARK: - Shapes

private struct PieHalf: View {
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
