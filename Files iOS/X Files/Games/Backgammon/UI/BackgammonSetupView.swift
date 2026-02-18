import SwiftUI

struct BackgammonSetupView: View {

    @State private var config: BackgammonConfig

    init(initialConfig: BackgammonConfig = BackgammonConfig()) {
        _config = State(initialValue: initialConfig)
    }

    // ✅ Evitamos requireCasa (no existe). Chequeamos modos explícitos.
    private var needsHomeSide: Bool {
        config.mode == .twoPlayersAdvisorHome || config.mode == .vsCPU
    }

    var body: some View {
        List {

            Section("Modo") {
                ForEach(BackgammonMode.allCases) { m in
                    Button {
                        config.mode = m
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(m.titulo).font(.subheadline.bold())
                                Text(m.descripcion).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: config.mode == m ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(config.mode == m ? .blue : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if needsHomeSide {
                Section("Jugador de la casa") {
                    Picker("Casa", selection: $config.homeSide) {
                        Text("Jugador 1").tag(BGSide.player1)
                        Text("Jugador 2").tag(BGSide.player2)
                    }
                    .pickerStyle(.segmented)
                }
            }

            Section {
                NavigationLink {
                    BackgammonNamesView(config: config)
                } label: {
                    Text("Continuar")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.horizontal, 16)
                }
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
