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

            // Ruleta (UI: mitad NEGRA / mitad BLANCA) + "Listo"
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
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.15), lineWidth: 2)
                    )

                VStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.title2)
                        .foregroundColor(.blue)

                    Text("Listo")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Circle())
            .onTapGesture {
                girarYAsignar()
            }

            Spacer()

            // Resultado
            if let result = finalColors {
                VStack(spacing: 12) {
                    tarjeta(
                        nombre: result.blackPlayer,
                        fondo: .black,
                        texto: "NEGRAS"
                    )

                    tarjeta(
                        nombre: result.whitePlayer,
                        fondo: .gray.opacity(0.15),
                        texto: "BLANCAS"
                    )
                }
                .padding(.horizontal)
            }

            // Continuar (LÓGICA: sin disabled, sin pop)
            Button {
                // Si aún no hay asignación, la hacemos aquí
                if finalColors == nil {
                    girarYAsignar()
                    return
                }

                // Ya asignado → avisamos al padre
                if let result = finalColors {
                    onAssigned(result)
                    // NO dismiss() -> no vuelve a nombres
                }
            } label: {
                Text("Continuar")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(26)
            }
            .padding(.horizontal)

            Spacer(minLength: 10)
        }
    }

    // MARK: - Lógica (NO UI)

    private func girarYAsignar() {
        guard !isSpinning else { return }
        isSpinning = true

        withAnimation(.easeOut(duration: 1.2)) {
            rotation += Double.random(in: 720...1080)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            asignarColores()
            isSpinning = false
        }
    }

    private func asignarColores() {
        let players = BackgammonPlayers(p1: player1Name, p2: player2Name)

        let assignment: BackgammonAssignment
        if Bool.random() {
            assignment = BackgammonAssignment(p1Color: .black, p2Color: .white)
        } else {
            assignment = BackgammonAssignment(p1Color: .white, p2Color: .black)
        }

        finalColors = BackgammonColorAssignment(players: players, assignment: assignment)
    }

    // MARK: - UI helpers

    private func tarjeta(nombre: String, fondo: Color, texto: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(nombre)
                .font(.headline)

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
