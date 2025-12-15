import Foundation

struct Equipo: Identifiable, Equatable {

    let id = UUID()

    // ---------------------------------------------------------
    // DATOS PRINCIPALES DEL EQUIPO
    // ---------------------------------------------------------
    var numero: Int                // Equipo #1 o #2
    var nombre: String             // Ej: "Equipo 1"
    var tipo: TipoEquipo           // .par o .impar

    var jugadores: [Jugador]       // Lista de jugadores del equipo
    var ordenJugadores: [Int]      // Orden global 1..8 asignado por la ruleta

    // ---------------------------------------------------------
    // PUNTAJES
    // ---------------------------------------------------------
    var puntajeActual: Int = 0         // puntaje de la partida actual
    var puntajeAcumulado: Int = 0      // acumulado en la sesión

    // Puntaje individual por jugador (paralelo a jugadores[])
    var puntajeIndividual: [Int]

    // ---------------------------------------------------------
    // INICIALIZADOR
    // ---------------------------------------------------------
    init(
        numero: Int,
        nombre: String,
        tipo: TipoEquipo,
        jugadores: [Jugador],
        ordenJugadores: [Int]
    ) {
        self.numero = numero
        self.nombre = nombre
        self.tipo = tipo
        self.jugadores = jugadores
        self.ordenJugadores = ordenJugadores

        // Inicializa puntaje individual de cada jugador en 0
        self.puntajeIndividual = Array(repeating: 0, count: jugadores.count)
    }
}
