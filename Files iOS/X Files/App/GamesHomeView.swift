import SwiftUI

struct GamesHomeView: View {

    let onSelect: (GameID) -> Void

    var body: some View {
        List {
            Section(header: Text("Juegos")) {
                ForEach(GameID.allCases) { game in
                    Button {
                        onSelect(game)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.title)
                                .font(.headline)
                            Text(game.subtitle)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Juegos")
    }
}
