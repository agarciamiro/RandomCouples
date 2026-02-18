import SwiftUI

struct BackgammonColorRouletteView: View {

    // MARK: - Inputs
    let player1Name: String
    let player2Name: String
    let onAssigned: (BackgammonColorAssignment) -> Void

    // MARK: - State
    @State private var finalColors: BackgammonColorAssignment? = nil
    @State private var isSpinning: Bool = false
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {

            // Header
            VStack(spacing: 6) {
                Text("Ruleta de colores")
                    .font(.title.bold())

                Text("Asigna BLANCAS y NEGRAS")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)

            Spacer()

            // Ruleta (UI: mitad NEGRA / mitad BLANCA) + estado "Listo" solo al final
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: .black, location: 0.00),
                                .init(color: .black, location: 0.50),
                                .init(color: .white, location: 0.50),
                                .init(color: .white, location: 1.00)
                            ]),
                            center: .center,
                            angle: .degrees(0)
                        )
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(rotation))
                    .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 2))

                VStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.title2.bold())
                        .foregroundColor(.blue)

                    Text(finalColors == nil ? "Toca para girar" : "Listo")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Circle())
            .onTapGesture { girarYAsignar() }

            Spacer()

            // Resultado (solo cuando ya asignó)
            if let r = finalColors {
                VStack(spacing: 14) {
                    tarjeta(nombre: r.blackPlayer, fondo: .black, texto: "NEGRAS")
                    tarjeta(nombre: r.whitePlayer, fondo: .white, texto: "BLANCAS")
                }
                .padding(.horizontal)
            }

            // Continuar: SOLO funciona cuando ya hay asignación
            Button {
                guard let result = finalColors else { return }
                // ✅ NO hacemos dismiss() aquí.
                // El flujo siguiente lo dispara el padre (BackgammonNamesView) al recibir onAssigned.
                onAssigned(result)
            } label: {
                Text("Continuar")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(finalColors == nil ? Color.gray.opacity(0.35) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(28)
                    .padding(.horizontal)
            }
            .disabled(finalColors == nil)

            Spacer(minLength: 18)
        }
    }

    // MARK: - Lógica

    private func girarYAsignar() {
        guard !isSpinning else { return }
        isSpinning = true

        withAnimation(.easeInOut(duration: 1.2)) {
            rotation += Double.random(in: 720...1440)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            let players = BackgammonPlayers(p1: player1Name, p2: player2Name)

            // Random simple: 50/50
            let assignment: BackgammonAssignment
            if Bool.random() {
                assignment = BackgammonAssignment(p1Color: .black, p2Color: .white)
            } else {
                assignment = BackgammonAssignment(p1Color: .white, p2Color: .black)
            }

            finalColors = BackgammonColorAssignment(players: players, assignment: assignment)
            isSpinning = false
        }
    }

    // MARK: - UI helper

    private func tarjeta(nombre: String, fondo: Color, texto: String) -> some View {
        // ✅ Contraste correcto para el NOMBRE (antes se perdía en negro sobre negro)
        let nombreColor: Color = (fondo == .black) ? .white : .black

        return VStack(alignment: .leading, spacing: 6) {
            Text(nombre)
                .font(.headline)
                .foregroundColor(nombreColor)

            Text(texto)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(fondo.opacity(0.8))
                .foregroundColor(fondo == .black ? .white : .black)
                .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(fondo)
        .cornerRadius(16)
    }
}
