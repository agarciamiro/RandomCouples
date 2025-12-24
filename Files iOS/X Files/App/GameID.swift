import Foundation

enum GameID: String, CaseIterable, Identifiable {
    case billar
    case backgammon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .billar: return "Billar"
        case .backgammon: return "Backgammon"
        }
    }

    var subtitle: String {
        switch self {
        case .billar: return "PAR vs IMPAR · turnos + bolas + bola 8"
        case .backgammon: return "1 vs 1 · modo guía (próximamente)"
        }
    }

    /// Nombre del PDF en el bundle SIN extensión .pdf
    var rulesPDFName: String? {
        switch self {
        case .billar: return "Reglas_Billar"
        case .backgammon: return "Reglas_Backgammon" // si no existe aún, puedes poner nil
        }
    }
}
