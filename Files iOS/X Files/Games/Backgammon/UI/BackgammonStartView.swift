import SwiftUI

struct BackgammonStartView: View {

    let config: BackgammonConfig

    // Mantengo init por compatibilidad
    init(config: BackgammonConfig = BackgammonConfig()) {
        self.config = config
    }

    var body: some View {
        BackgammonNamesView(config: config)
    }
}
