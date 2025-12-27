import SwiftUI
import Foundation

struct BackgammonColorRouletteView: View {

    let player1Name: String
    let player2Name: String

    /// Devuelve el assignment al padre
    let onContinue: (BackgammonColorAssignment) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var spinning = false
    @State private var rotation: Double = 0
    @State private var hasResult = false

    /// true => player1 = NEGRAS, false => player2 = NEGRAS
    @State private var p1IsBlack = true

    // MARK: - Derived

    private var assignment: BackgammonColorAssignment {
        let black = p1IsBlack ? player1Name : player2Name
        let white = p1IsBlack ? player2Name : player1Name

        let blackSide: BGSide = p1IsBlack ? .player1 : .player2
        let whiteSide: BGSide = p1IsBlack ? .player2 : .player1

        // IMPORTANTÍSIMO:
        // Si tu BackgammonColorAssignment está declarado con propiedades en este orden:
        // blackSide, whiteSide, blackPlayer, whitePlayer
        // el memberwise init "espera" esos labels primero.
        return BackgammonColorAssignment(
            blackSide: blackSide,
            whiteSide: whiteSide,
            blackPlayer: black,
            whitePlayer: white
        )
    }

    var body: some View {
        VStack(spacing: 16) {

            Text("Ruleta de colores")
                .font(.title.bold())
                .padding(.top, 8)

            Text("Asigna BLANCAS y NEGRAS")
                .font(.footnote)
                .foregroundColor(.secondary)

            // Wheel + pointer
            ZStack(alignment: .top) {
                BGColorWheel()
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)

                BGColorPointer()
                    .padding(.top, -6)
            }
            .frame(width: 280, height: 280)
            .padding(.top, 6)

            // Cards
            VStack(spacing: 12) {
                playerCard(
                    name: assignment.blackPlayer,
                    piece: "NEGRAS",
                    dark: true
                )

                playerCard(
                    name: assignment.whitePlayer,
                    piece: "BLANCAS",
                    dark: false
                )
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 6)

            // Buttons
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
                .padding(.bottom, 10)
            } else {
                Button {
                    onContinue(assignment)
                    // si estás dentro de NavigationStack normalmente NO quieres dismiss aquí,
                    // pero lo dejo como opción segura si la pantalla se presenta como sheet.
                    // Si no quieres cerrar, comenta la línea:
                    // dismiss()
                } label: {
                    Text("Continuar")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .navigationTitle("Backgammon")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - UI pieces

    private func playerCard(name: String, piece: String, dark: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(name)
                .font(.headline)
                .foregroundColor(dark ? .white : .black)

            Text(piece)
                .font(.title3.bold())
                .foregroundColor(dark ? .white : .black)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dark ? Color.black.opacity(0.85) : Color.gray.opacity(0.20))
        .cornerRadius(14)
    }

    // MARK: - Logic

    private func spinOnce() {
        guard !spinning else { return }
        spinning = true
        hasResult = false

        // Animación de ruleta (solo visual)
        let extraTurns = Double(Int.random(in: 3...6)) * 360
        let randomAngle = Double.random(in: 0..<360)

        withAnimation(.easeOut(duration: 1.2)) {
            rotation += extraTurns + randomAngle
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            // Resultado real (simple y robusto)
            // Si quieres atarlo al ángulo final, lo hacemos después.
            p1IsBlack = Bool.random()

            spinning = false
            hasResult = true
        }
    }
}

// MARK: - Wheel (colores)

private struct BGColorWheel: View {
    var body: some View {
        ZStack {
            // Mitad NEGRAS
            Circle()
                .trim(from: 0.0, to: 0.5)
                .rotation(.degrees(-90))
                .fill(Color.black.opacity(0.88))

            // Mitad BLANCAS (gris suave)
            Circle()
                .trim(from: 0.5, to: 1.0)
                .rotation(.degrees(-90))
                .fill(Color.gray.opacity(0.30))

            Circle()
                .stroke(Color.black.opacity(0.08), lineWidth: 2)

            // Textos
            Text("NEGRAS")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(25))
                .offset(x: 76, y: -32)

            Text("BLANCAS")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black.opacity(0.75))
                .rotationEffect(.degrees(-155))
                .offset(x: -70, y: 36)

            // Centro
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 110, height: 110)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)

            VStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                Text("Listo")
                    .font(.headline)
            }
            .foregroundColor(.primary)
        }
    }
}

// MARK: - Pointer (renombrado para evitar redeclarations)

private struct BGColorPointer: View {
    var body: some View {
        BGColorTriangle()
            .fill(Color.orange.opacity(0.95))
            .frame(width: 20, height: 16)
            .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 4)
    }
}

private struct BGColorTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
