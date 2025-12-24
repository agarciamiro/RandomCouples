import Foundation

struct ResultadoRuleta {
    
    /// Lista de equipos generados por la ruleta
    let equipos: [Equipo]
    
    /// Orden global de jugadores (1–8, o 1–2, 1–4, 1–6 según cantidad)
    let ordenJugadores: [String]
}
