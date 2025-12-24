import SwiftUI

enum AppRoute: Hashable {
    case landing
    case gamesHome
    case gameHub(GameID)
    case rules(GameID)
    case start(GameID)
}

struct AppRouterView: View {

    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {

            // Root: tu pantalla branding (la de siempre)
            LandingView {
                path.append(.gamesHome)
            }

            .navigationDestination(for: AppRoute.self) { route in
                switch route {

                case .landing:
                    LandingView {
                        path.append(.gamesHome)
                    }

                case .gamesHome:
                    GamesHomeView { game in
                        path.append(.gameHub(game))
                    }

                case .gameHub(let game):
                    GameHubView(
                        game: game,
                        onRules: { path.append(.rules(game)) },
                        onStart: { path.append(.start(game)) }
                    )

                case .rules(let game):
                    GameRulesView(game: game)

                case .start(let game):
                    switch game {
                    case .billar:
                        // ✅ Tu flujo actual de Billar
                        PartidaView()

                    case .backgammon:
                        // Placeholder por ahora
                        BackgammonStartView()
                    }
                }
            }
        }
    }
}
