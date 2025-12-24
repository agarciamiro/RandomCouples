import SwiftUI

struct GameHubView: View {

    let game: GameID
    let onRules: () -> Void
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 18) {

            VStack(spacing: 6) {
                Text(game.title).font(.largeTitle.bold())
                Text(game.subtitle).font(.subheadline).foregroundColor(.secondary)
            }
            .padding(.top, 10)

            Button(action: onRules) {
                HStack {
                    Text("📘 Reglas")
                        .font(.title3.bold())
                    Spacer()
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(14)
            }

            Button(action: onStart) {
                HStack {
                    Text("▶️ Empezar")
                        .font(.title3.bold())
                    Spacer()
                }
                .padding()
                .background(.thinMaterial)
                .cornerRadius(14)
            }

            Spacer()
        }
        .padding()
        .navigationTitle(game.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
