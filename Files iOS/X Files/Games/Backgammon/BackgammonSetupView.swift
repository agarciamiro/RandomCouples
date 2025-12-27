import SwiftUI

struct BackgammonSetupView: View {

    @State private var config = BackgammonConfig()

    var body: some View {
        VStack(spacing: 14) {

            VStack(spacing: 6) {
                Text("Configurar Backgammon")
                    .font(.title2.bold())
                Text("Elige el modo de juego")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)

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

                if config.mode.requiereCasa {
                    Section("Jugador de la casa") {
                        Picker("Casa", selection: $config.homeSide) {
                            Text("Jugador 1").tag(BGSide.player1)
                            Text("Jugador 2").tag(BGSide.player2)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
            .listStyle(.insetGrouped)

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
            .padding(.bottom, 14)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
