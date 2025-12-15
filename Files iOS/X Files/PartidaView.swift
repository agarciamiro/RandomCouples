import SwiftUI

struct PartidaView: View {

    @State private var teamCount = 1   // selector 1–4 (→ 2, 4, 6, 8 jugadores)

    var body: some View {
        VStack(spacing: 32) {

            Text("Configurar Partida")
                .font(.largeTitle.bold())

            // Selector 1–4 equipos
            Picker("Número de Equipos", selection: $teamCount) {
                ForEach(1...4, id: \.self) { value in
                    Text("\(value) equipos (\(value * 2) jugadores)")
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 160)

            // Continuar → ingresar nombres
            NavigationLink {
                IngresarNombresView(teamCount: teamCount)
            } label: {
                Text("Ingresar nombres")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Partida")
        .navigationBarTitleDisplayMode(.inline)
    }
}
