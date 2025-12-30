import SwiftUI

struct BackgammonFirstRollView: View {

    let config: BackgammonConfig
    let players: BackgammonPlayers
    let assignment: BackgammonAssignment

    @State private var lastP1: Int? = nil
    @State private var lastP2: Int? = nil

    // Si empatan, sube y se vuelve a tirar tocando la ruleta
    @State private var tieMultiplier: Int = 1

    @State private var resolved: BackgammonOpening? = nil
    @State private var rolling: Bool = false
    @State private var rotation: Double = 0

    // ✅ Navegación al TABLERO (directo, sin pantalla intermedia)
    @State private var goBoard: Bool = false
    @State private var nextColors: BackgammonColorAssignment? = nil
    @State private var nextStart: BackgammonStartDiceResult? = nil

    var body: some View {
        VStack(spacing: 18) {

            VStack(spacing: 6) {
                Text("Inicio de partida")
                    .font(.title2.bold())

                Text("Cada jugador tira 1 dado. Si empatan, se repite.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
            }
            .padding(.top, 10)

            Spacer()

            // 🎲 Ruleta / acción principal (tocar para tirar)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.black.opacity(0.95), .gray.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(rotation))
                    .overlay(
                        Circle().stroke(Color.black.opacity(0.15), lineWidth: 2)
                    )

                VStack(spacing: 6) {
                    Image(systemName: "die.face.5")
                        .font(.title2.bold())
                        .foregroundColor(.blue)

                    Text(centerText)
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Circle())
            .onTapGesture { tirar() }

            Spacer()

            // Cards de resultado (siempre visibles con placeholder —)
            VStack(spacing: 10) {
                rollCard(name: players.p1, value: lastP1, color: assignment.p1Color)
                rollCard(name: players.p2, value: lastP2, color: assignment.p2Color)
            }
            .padding(.horizontal, 16)

            if tieMultiplier > 1 && resolved == nil {
                Text("Empate: vuelve a tocar para tirar (x\(tieMultiplier))")
                    .font(.footnote.bold())
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.25))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            }

            if let opening = resolved {
                let starterName = (opening.starter == .player1) ? players.p1 : players.p2

                Text("Empieza: \(starterName) — Dados iniciales: \(opening.openingDice[0]) + \(opening.openingDice[1])")
                    .font(.footnote.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.top, 6)
            }

            // ✅ Continuar: va DIRECTO al TABLERO
            Button {
                guard let opening = resolved else { return }
                nextColors = opening.colors
                nextStart = opening.startResult
                goBoard = true
            } label: {
                Text("Continuar")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .disabled(resolved == nil)

            // ✅ Navegación invisible al tablero
            NavigationLink(
                destination: destinationBoardView(),
                isActive: $goBoard
            ) { EmptyView() }
            .hidden()

            Spacer(minLength: 14)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - UI

    private var centerText: String {
        if resolved != nil { return "Listo" }
        if rolling { return "Tirando..." }
        return "Toca para tirar"
    }

    private func rollCard(name: String, value: Int?, color: BGColor) -> some View {
        HStack {
            Text(name).font(.subheadline.bold())
            Spacer()
            Text(value == nil ? "—" : "\(value!)")
                .font(.title3.bold())
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
    }

    @ViewBuilder
    private func destinationBoardView() -> some View {
        if let c = nextColors, let s = nextStart {
            BackgammonBoardView(colors: c, startResult: s)
        } else {
            // Fallback ultra seguro (no debería verse)
            EmptyView()
        }
    }

    // MARK: - Lógica

    private func tirar() {
        // Si ya resolvió, no vuelve a tirar (flujo limpio)
        guard resolved == nil else { return }
        guard !rolling else { return }

        rolling = true

        withAnimation(.easeInOut(duration: 1.1)) {
            rotation += Double.random(in: 720...1440)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            let p1 = Int.random(in: 1...6)
            let p2 = Int.random(in: 1...6)

            lastP1 = p1
            lastP2 = p2

            // Empate: no resolvemos, solo sube multiplicador y el usuario vuelve a tocar
            if p1 == p2 {
                tieMultiplier += 1
                rolling = false
                return
            }

            // Mapear dados a NEGRAS/BLANCAS según assignment
            let blackDie: Int
            let whiteDie: Int
            if assignment.p1Color == .black {
                blackDie = p1
                whiteDie = p2
            } else {
                blackDie = p2
                whiteDie = p1
            }

            let start = BackgammonStartDiceResult(
                blackDie: blackDie,
                whiteDie: whiteDie,
                tieCount: max(0, tieMultiplier - 1)
            )

            resolved = BackgammonOpening(
                config: config,
                players: players,
                assignment: assignment,
                startResult: start
            )

            rolling = false
        }
    }
}
