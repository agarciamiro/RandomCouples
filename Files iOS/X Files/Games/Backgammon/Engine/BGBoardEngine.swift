import Foundation

struct BGBoardEngine {

    static func moveDirection(
        current: BGPiece,
        casaPiece: BGPiece
    ) -> Int {
        return (current == casaPiece) ? -1 : 1
    }

    static func targetIndex(
        from: Int,
        die: Int,
        direction: Int
    ) -> Int {
        return from + (direction * die)
    }
}
