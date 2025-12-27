import SwiftUI
import Foundation

/// Vista “puente”. Puede no usarse si vas directo a Tablero.
/// La dejamos compilable con inits compatibles para que NO vuelva a romper.
struct BackgammonTurnDiceView: View {

    let colors: BackgammonColorAssignment
    let startResult: BackgammonStartDiceResult

    // ✅ Init principal (recomendado)
    init(colors: BackgammonColorAssignment, startResult: BackgammonStartDiceResult) {
        self.colors = colors
        self.startResult = startResult
    }

    // ✅ Compatibilidad por si en algún lado lo llamas como `start:`
    init(colors: BackgammonColorAssignment, start: BackgammonStartDiceResult) {
        self.init(colors: colors, startResult: start)
    }

    // ✅ Compatibilidad por si en algún lado lo llamas como `result:`
    init(colors: BackgammonColorAssignment, result: BackgammonStartDiceResult) {
        self.init(colors: colors, startResult: result)
    }

    // ✅ Compatibilidad por si en algún lado lo llamabas SIN colors (no recomendado, pero compila)
    init(startResult: BackgammonStartDiceResult) {
        self.startResult = startResult
        // OJO: orden correcto del init => whitePlayer primero, blackPlayer después
        self.colors = BackgammonColorAssignment(
            whitePlayer: "BLANCAS",
            blackPlayer: "NEGRAS"
        )
    }

    var body: some View {
        // Si tu BackgammonBoardView ya existe con este init, perfecto:
        BackgammonBoardView(colors: colors, startResult: startResult)
    }
}
