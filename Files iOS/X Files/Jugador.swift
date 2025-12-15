import Foundation

struct Jugador: Identifiable, Equatable {
    let id = UUID()
    let nombre: String
    var puntos: Int = 0         // Puntaje actual
    var puntosAcumulados: Int = 0  // Puntaje de partidas anteriores
}
