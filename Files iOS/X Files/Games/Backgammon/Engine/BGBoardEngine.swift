import Foundation

struct BGBoardEngine {
    
    static func moveDirection(
        current: BGPiece,
        casaPiece: BGPiece
    ) -> Int {
        
        // Casa va 24 → 1
        // Visita va 1 → 24
        return (current == casaPiece) ? -1 : 1
    }
}
