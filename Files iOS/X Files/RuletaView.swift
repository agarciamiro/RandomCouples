import SwiftUI

struct RuletaView: View {

    let jugadores: [String]

    @State private var angulo: Double = 0
    @State private var mostrarBoton = true
    @State private var equiposGenerados: [Equipo] = []
    @State private var ordenGlobal: [String] = []

    var body: some View {
        VStack(spacing: 30) {

            Text("🎡 Ruleta de Par / Impar")
                .font(.largeTitle.bold())

            // RUEDA
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .red, .blue]),
                            center: .center
                        )
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(angulo))
                    .animation(.easeOut(duration: 2), value: angulo)

                TrianglePointer()
                    .fill(Color.black)
                    .frame(width: 24, height: 24)
                    .offset(y: -150)
            }

            // GIRAR
            if mostrarBoton {
                Button("GIRAR") { iniciarGiro() }
                    .font(.title3.bold())
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            // CONTINUAR
            if !equiposGenerados.isEmpty {
                NavigationLink(
                    destination: AsignacionView(
                        equipos: $equiposGenerados,
                        ordenJugadores: ordenGlobal
                    )
                ) {
                    Text("CONTINUAR")
                        .font(.title3.bold())
                        .padding()
                        .frame(maxWidth: 220)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            Spacer()
        }
        .padding()
    }

    // -------------------------------------------------------------
    // MARK: - Giro
    // -------------------------------------------------------------
    private func iniciarGiro() {
        mostrarBoton = false

        let giro = Double.random(in: 900...1500)
        angulo += giro

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            generarEquiposYOrden()
        }
    }

    // -------------------------------------------------------------
    // MARK: - Equipos + Tipo + Orden alternado PAR/IMPAR
    // -------------------------------------------------------------
    private func generarEquiposYOrden() {

        let total = jugadores.count
        let mezclados = jugadores.shuffled()

        var grupos: [[String]] = []

        switch total {
        case 2:
            grupos = [[mezclados[0]], [mezclados[1]]]

        case 4:
            grupos = [
                [mezclados[0], mezclados[1]],
                [mezclados[2], mezclados[3]]
            ]

        case 6:
            grupos = [
                [mezclados[0], mezclados[1], mezclados[2]],
                [mezclados[3], mezclados[4], mezclados[5]]
            ]

        case 8:
            // ✅ CAMBIO: 8 jugadores -> 2 equipos de 4 (ya no 4 equipos de 2)
            grupos = [
                [mezclados[0], mezclados[1], mezclados[2], mezclados[3]],
                [mezclados[4], mezclados[5], mezclados[6], mezclados[7]]
            ]

        default:
            grupos = []
        }

        guard !grupos.isEmpty else {
            equiposGenerados = []
            ordenGlobal = []
            mostrarBoton = true
            return
        }

        // 1) Asignación PAR/IMPAR a equipos
        // (Para tu app, normalmente serán 2 equipos -> 1 PAR y 1 IMPAR)
        let asignacionTipo: [TipoEquipo] = {
            if grupos.count == 4 {
                // (por si algún día vuelves a 4 equipos)
                let indices = Array(0..<4).shuffled()
                let parSet = Set(indices.prefix(2))
                return (0..<4).map { parSet.contains($0) ? .par : .impar }
            } else {
                let empiezaPar = Bool.random()
                return [
                    empiezaPar ? .par : .impar,
                    empiezaPar ? .impar : .par
                ]
            }
        }()

        // 2) Crear equipos (ordenJugadores se llena después)
        var nuevos: [Equipo] = []
        for i in grupos.indices {
            let jugadoresObj = grupos[i].map { Jugador(nombre: $0) }

            let eq = Equipo(
                numero: i + 1,
                nombre: "Equipo \(i + 1)",
                tipo: asignacionTipo[i],
                jugadores: jugadoresObj,
                ordenJugadores: []
            )
            nuevos.append(eq)
        }

        // 3) OrdenGlobal alternado PAR/IMPAR
        let nombresPar = nuevos
            .filter { $0.tipo == .par }
            .flatMap { $0.jugadores.map { $0.nombre } }
            .shuffled()

        let nombresImpar = nuevos
            .filter { $0.tipo == .impar }
            .flatMap { $0.jugadores.map { $0.nombre } }
            .shuffled()

        var colaPar = nombresPar
        var colaImpar = nombresImpar

        let empiezaConPar = Bool.random()
        var turnoPar = empiezaConPar

        var orden: [String] = []
        while !colaPar.isEmpty || !colaImpar.isEmpty {

            if turnoPar {
                if !colaPar.isEmpty {
                    orden.append(colaPar.removeFirst())
                } else if !colaImpar.isEmpty {
                    orden.append(colaImpar.removeFirst())
                }
            } else {
                if !colaImpar.isEmpty {
                    orden.append(colaImpar.removeFirst())
                } else if !colaPar.isEmpty {
                    orden.append(colaPar.removeFirst())
                }
            }

            turnoPar.toggle()
        }

        ordenGlobal = orden

        // 4) Ranking numérico global
        var ordenNumerico: [String: Int] = [:]
        for (idx, nombre) in ordenGlobal.enumerated() {
            ordenNumerico[nombre] = idx + 1
        }

        // 5) Llenar ordenJugadores por equipo
        for i in nuevos.indices {
            let ordenLocal: [Int] = nuevos[i].jugadores.map { jugador in
                ordenNumerico[jugador.nombre] ?? 0
            }
            nuevos[i].ordenJugadores = ordenLocal
        }

        equiposGenerados = nuevos
    }
}

// Puntero de la ruleta
struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
