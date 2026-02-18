import Foundation

enum BackgammonMode: String, CaseIterable, Identifiable {
    case vsCPU
    case twoPlayersDice
    case twoPlayersAdvisorBoth
    case twoPlayersAdvisorHome

    var id: String { rawValue }

    var titulo: String {
        switch self {
        case .vsCPU: return "1) 1 vs Computadora"
        case .twoPlayersDice: return "2) 2 Jugadores (dados/ruleta)"
        case .twoPlayersAdvisorBoth: return "3) 2 Jugadores (IA ayuda a ambos)"
        case .twoPlayersAdvisorHome: return "4) 2 Jugadores (IA solo a Casa)"
        }
    }

    var descripcion: String {
        switch self {
        case .vsCPU:
            return "Tú juegas contra la computadora."
        case .twoPlayersDice:
            return "Solo ruletas: colores, inicio y dados."
        case .twoPlayersAdvisorBoth:
            return "La computadora sugiere la mejor jugada para ambos."
        case .twoPlayersAdvisorHome:
            return "La computadora sugiere solo al jugador de la casa."
        }
    }

    var requiereCasa: Bool {
        self == .twoPlayersAdvisorHome
    }
}
