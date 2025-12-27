import SwiftUI

struct BackgammonTurnDiceView: View {

    let colors: BackgammonColorAssignment
    let startResult: BackgammonStartDiceResult

    init(colors: BackgammonColorAssignment, startResult: BackgammonStartDiceResult) {
        self.colors = colors
        self.startResult = startResult
    }

    // Compatibilidad por si en algún lado lo llamas distinto:
    init(colors: BackgammonColorAssignment, result: BackgammonStartDiceResult) {
        self.init(colors: colors, startResult: result)
    }

    init(colors: BackgammonColorAssignment, start: BackgammonStartDiceResult) {
        self.init(colors: colors, startResult: start)
    }

    var body: some View {
        BackgammonBoardView(colors: colors, startResult: startResult)
    }
}
