import Foundation

struct BackgammonDiceEngine {

    static func rollDie() -> Int {
        Int.random(in: 1...6)
    }

    /// Dados normales (2 dados). Si salen dobles => 4 movimientos.
    static func rollTurnDiceMoves() -> [Int] {
        let a = rollDie()
        let b = rollDie()
        if a == b { return [a, a, a, a] }
        return [a, b]
    }

    /// Tirada de apertura: 1 dado por jugador. Deben ser distintos.
    static func rollOpeningDiceDistinct() -> (p1: Int, p2: Int) {
        var a = rollDie()
        var b = rollDie()
        while a == b {
            a = rollDie()
            b = rollDie()
        }
        return (a, b)
    }
}
