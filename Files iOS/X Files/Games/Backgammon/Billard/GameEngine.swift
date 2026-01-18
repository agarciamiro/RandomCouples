import Foundation
import Combine

// Motor de turnos PAR/IMPAR:
// - Construye el orden de PAR y el orden de IMPAR usando eq.ordenJugadores (ranking global).
// - Alterna tipo en cada cambio de turno.
// - Si modoAutoAvance = true y anota bola válida -> NO avanza (sigue el mismo jugador).
// - Si hay falta -> avanza y deja bolaEnManoParaSiguiente = true.
//
// ✅ FIX IMPORTANTE:
// Si NO se pasa "empieza", ahora empieza el que tenga el menor orden global (#1 real),
// para que coincida con tu "Orden de Juego" en Asignación (ya no random).

final class TurnosEngine: ObservableObject {

    struct Turno: Equatable {
        let tipo: TipoEquipo
        let equipoNumero: Int
        let jugadorNombre: String
    }

    private struct RankedTurno {
        let orden: Int
        let turno: Turno
    }

    // Config
    @Published var modoAutoAvance: Bool = false

    // Estado visible
    @Published private(set) var empiezaPartida: TipoEquipo
    @Published private(set) var turnoActual: Turno
    @Published private(set) var bolaEnManoParaSiguiente: Bool = false

    // Interno
    private let ordenPar: [Turno]
    private let ordenImpar: [Turno]

    // Índices por tipo:
    // -1 significa “ese tipo aún no ha jugado / no se ha mostrado su primer turno”
    private var idxPar: Int = -1
    private var idxImpar: Int = -1

    private var tipoActual: TipoEquipo

    // MARK: - Init
    init(equipos: [Equipo], empieza: TipoEquipo? = nil) {

        func buildRanked(tipo: TipoEquipo) -> [RankedTurno] {
            var tmp: [RankedTurno] = []

            for eq in equipos where eq.tipo == tipo {
                for (jIdx, j) in eq.jugadores.enumerated() {
                    let orden = (jIdx < eq.ordenJugadores.count) ? eq.ordenJugadores[jIdx] : 9999
                    tmp.append(
                        RankedTurno(
                            orden: orden,
                            turno: Turno(tipo: tipo, equipoNumero: eq.numero, jugadorNombre: j.nombre)
                        )
                    )
                }
            }

            tmp.sort { a, b in
                if a.orden != b.orden { return a.orden < b.orden }
                return a.turno.jugadorNombre < b.turno.jugadorNombre
            }

            return tmp
        }

        // 1) Construir rankings locales
        let rankedParLocal = buildRanked(tipo: .par)
        let rankedImparLocal = buildRanked(tipo: .impar)

        let ordenParLocal = rankedParLocal.map { $0.turno }
        let ordenImparLocal = rankedImparLocal.map { $0.turno }

        // 2) Elegir quién empieza (determinista)
        let startLocal: TipoEquipo = {
            if let empieza { return empieza }

            let pOrden = rankedParLocal.first?.orden
            let iOrden = rankedImparLocal.first?.orden

            switch (pOrden, iOrden) {
            case let (p?, i?):
                if p != i { return (p < i) ? .par : .impar }
                // desempate estable por nombre
                let pn = rankedParLocal.first?.turno.jugadorNombre ?? ""
                let inn = rankedImparLocal.first?.turno.jugadorNombre ?? ""
                return (pn <= inn) ? .par : .impar

            case (.some, .none):
                return .par
            case (.none, .some):
                return .impar
            default:
                // caso extremo: sin jugadores en ambos
                return Bool.random() ? .par : .impar
            }
        }()

        // 3) Definir primer turno consistente + fallback
        var empiezaFinal = startLocal
        var tipoActualLocal = startLocal
        var idxParInit = -1
        var idxImparInit = -1
        var turnoInicial = Turno(tipo: startLocal, equipoNumero: 1, jugadorNombre: "—")

        if startLocal == .par, let first = ordenParLocal.first {
            idxParInit = 0
            turnoInicial = first
        } else if startLocal == .impar, let first = ordenImparLocal.first {
            idxImparInit = 0
            turnoInicial = first
        } else if let fallback = ordenParLocal.first {
            empiezaFinal = .par
            tipoActualLocal = .par
            idxParInit = 0
            turnoInicial = fallback
        } else if let fallback = ordenImparLocal.first {
            empiezaFinal = .impar
            tipoActualLocal = .impar
            idxImparInit = 0
            turnoInicial = fallback
        }

        // 4) Inicializar stored properties (sin usar self antes de tiempo)
        self.ordenPar = ordenParLocal
        self.ordenImpar = ordenImparLocal

        self.empiezaPartida = empiezaFinal
        self.tipoActual = tipoActualLocal
        self.turnoActual = turnoInicial

        self.idxPar = idxParInit
        self.idxImpar = idxImparInit
    }

    // MARK: - API pública

    /// Manual: siempre avanza al siguiente jugador del OTRO tipo
    func siguienteTurno() {
        bolaEnManoParaSiguiente = false
        avanzarAlSiguiente(fueFalta: false)
    }

    /// Registrar lo que pasó en el tiro.
    /// - anotoBolaValida: metió bola de su signo
    /// - fueFalta: blanca / bola rival / no toca bola / etc.
    func registrarTiro(anotoBolaValida: Bool, fueFalta: Bool) {

        if fueFalta {
            avanzarAlSiguiente(fueFalta: true)
            return
        }

        // Si Auto ON y anotó válida -> se queda (no avanza)
        if modoAutoAvance && anotoBolaValida {
            bolaEnManoParaSiguiente = false
            return
        }

        // Si no anotó -> avanza
        avanzarAlSiguiente(fueFalta: false)
    }

    func limpiarBolaEnMano() {
        bolaEnManoParaSiguiente = false
    }

    // MARK: - Interno
    private func avanzarAlSiguiente(fueFalta: Bool) {

        bolaEnManoParaSiguiente = fueFalta

        // Alternar tipo
        tipoActual = (tipoActual == .par) ? .impar : .par

        // Elegir turno del tipoActual SIN saltarse el primero
        if tipoActual == .par, !ordenPar.isEmpty {
            if idxPar == -1 { idxPar = 0 } else { idxPar = (idxPar + 1) % ordenPar.count }
            turnoActual = ordenPar[idxPar]
            return
        }

        if tipoActual == .impar, !ordenImpar.isEmpty {
            if idxImpar == -1 { idxImpar = 0 } else { idxImpar = (idxImpar + 1) % ordenImpar.count }
            turnoActual = ordenImpar[idxImpar]
            return
        }

        // Si falta una lista, cae a la que exista
        if !ordenPar.isEmpty {
            if idxPar == -1 { idxPar = 0 } else { idxPar = (idxPar + 1) % ordenPar.count }
            tipoActual = .par
            turnoActual = ordenPar[idxPar]
        } else if !ordenImpar.isEmpty {
            if idxImpar == -1 { idxImpar = 0 } else { idxImpar = (idxImpar + 1) % ordenImpar.count }
            tipoActual = .impar
            turnoActual = ordenImpar[idxImpar]
        }
    }
}
