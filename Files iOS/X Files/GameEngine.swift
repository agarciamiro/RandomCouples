import Foundation
import Combine

// ===============================================================
//  GameEngine.swift
//  - Usa tus modelos existentes: Equipo / Jugador / TipoEquipo
//  - Mantiene orden interno por equipo (según ordenJugadores)
//  - Permite generar el ORDEN GLOBAL de la partida según quién empieza
//  - "Siguiente partida": alterna quién empieza (PAR <-> IMPAR)
// ===============================================================

extension Equipo {

    /// Jugadores en el orden fijo del equipo (ordenJugadores ascendente).
    /// Si hay inconsistencia entre cantidades, usa el orden actual del array.
    var jugadoresEnOrdenFijo: [Jugador] {
        guard ordenJugadores.count == jugadores.count else { return jugadores }

        return zip(ordenJugadores, jugadores)
            .sorted { $0.0 < $1.0 }
            .map { $0.1 }
    }
}

struct TurnoActual {
    let equipoNumero: Int
    let equipoTipo: TipoEquipo
    let jugador: Jugador
}

final class TurnosEngine: ObservableObject {

    @Published private(set) var empiezaPartida: TipoEquipo
    @Published private(set) var turnoTipoActual: TipoEquipo

    private var idxJugadorPorEquipo: [Int:Int] = [:]   // equipo.numero -> índice jugador
    private var idxEquipoPar: Int = 0
    private var idxEquipoImpar: Int = 0

    init(empiezaPartida: TipoEquipo) {
        self.empiezaPartida = empiezaPartida
        self.turnoTipoActual = empiezaPartida
    }

    func siguientePartida() {
        empiezaPartida = (empiezaPartida == .par) ? .impar : .par
        turnoTipoActual = empiezaPartida

        idxJugadorPorEquipo = [:]
        idxEquipoPar = 0
        idxEquipoImpar = 0
    }

    func siguienteTurno(equipos: [Equipo]) -> TurnoActual? {
        guard !equipos.isEmpty else { return nil }

        let parTeams = equipos.filter { $0.tipo == .par }.sorted { $0.numero < $1.numero }
        let imparTeams = equipos.filter { $0.tipo == .impar }.sorted { $0.numero < $1.numero }

        func pickTeam(for tipo: TipoEquipo) -> Equipo? {
            if tipo == .par, !parTeams.isEmpty {
                let t = parTeams[idxEquipoPar % parTeams.count]
                idxEquipoPar += 1
                return t
            }
            if tipo == .impar, !imparTeams.isEmpty {
                let t = imparTeams[idxEquipoImpar % imparTeams.count]
                idxEquipoImpar += 1
                return t
            }
            return (tipo == .par) ? imparTeams.first : parTeams.first
        }

        let tipoActual = turnoTipoActual
        guard let equipo = pickTeam(for: tipoActual) else { return nil }

        let lista = equipo.jugadoresEnOrdenFijo
        guard !lista.isEmpty else { return nil }

        let idx = idxJugadorPorEquipo[equipo.numero, default: 0]
        let jugador = lista[idx % lista.count]
        idxJugadorPorEquipo[equipo.numero] = idx + 1

        turnoTipoActual = (turnoTipoActual == .par) ? .impar : .par

        return TurnoActual(equipoNumero: equipo.numero, equipoTipo: equipo.tipo, jugador: jugador)
    }

    /// ✅ Orden global de la partida (nombres en el orden real),
    /// empezando por `empiezaPartida` y alternando PAR/IMPAR, manteniendo
    /// el orden interno fijo por equipo.
    func ordenGlobal(equipos: [Equipo]) -> [String] {
        guard !equipos.isEmpty else { return [] }

        let totalJugadores = equipos.reduce(0) { $0 + $1.jugadores.count }

        let parTeams = equipos.filter { $0.tipo == .par }.sorted { $0.numero < $1.numero }
        let imparTeams = equipos.filter { $0.tipo == .impar }.sorted { $0.numero < $1.numero }

        var turno: TipoEquipo = empiezaPartida
        var idxJugador: [Int:Int] = [:]
        var idxPar = 0
        var idxImpar = 0

        func pickTeam(for tipo: TipoEquipo) -> Equipo? {
            if tipo == .par, !parTeams.isEmpty {
                let t = parTeams[idxPar % parTeams.count]
                idxPar += 1
                return t
            }
            if tipo == .impar, !imparTeams.isEmpty {
                let t = imparTeams[idxImpar % imparTeams.count]
                idxImpar += 1
                return t
            }
            return (tipo == .par) ? imparTeams.first : parTeams.first
        }

        var orden: [String] = []
        orden.reserveCapacity(totalJugadores)

        for _ in 0..<totalJugadores {
            let tipoActual = turno
            guard let equipo = pickTeam(for: tipoActual) else { break }

            let lista = equipo.jugadoresEnOrdenFijo
            if lista.isEmpty { break }

            let i = idxJugador[equipo.numero, default: 0]
            let jugador = lista[i % lista.count]
            idxJugador[equipo.numero] = i + 1

            orden.append(jugador.nombre)

            turno = (turno == .par) ? .impar : .par
        }

        return orden
    }
}
