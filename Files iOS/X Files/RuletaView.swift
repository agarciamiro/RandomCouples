import SwiftUI

struct RuletaView: View {

    let jugadores: [String]

    @State private var angulo: Double = 0
    @State private var mostrarBotonGirar = true
    @State private var mostrandoGenerando = false

    @State private var equiposGenerados: [Equipo] = []
    @State private var ordenGlobal: [String] = []

    // ✅ Navegación moderna (iOS 16+), sin deprecated
    @State private var irAAsignacion = false

    var body: some View {
        VStack(spacing: 26) {

            // -------------------------------------------------
            // TÍTULO
            // -------------------------------------------------
            VStack(spacing: 4) {
                Text("Asignación Aleatoria de:")
                    .font(.title2.bold())

                Text("signo · equipos · orden de jugadores")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 8)

            // -------------------------------------------------
            // RULETA + PUNTERO
            // -------------------------------------------------
            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                Color.blue,
                                Color.purple,
                                Color.red,
                                Color.purple,
                                Color.blue
                            ]),
                            center: .center
                        )
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(angulo))
                    .animation(.easeOut(duration: 2.2), value: angulo)

                TrianglePointer()
                    .fill(Color.black)
                    .frame(width: 26, height: 26)
                    .offset(y: -160)
            }

            // -------------------------------------------------
            // BOTÓN GIRAR / ESTADO GENERANDO
            // -------------------------------------------------
            if mostrarBotonGirar {
                Button {
                    iniciarGiro()
                } label: {
                    Text("GIRAR")
                        .font(.title3.bold())
                        .padding()
                        .frame(maxWidth: 220)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
            } else {
                if mostrandoGenerando {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Generando asignación…")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding()

        // Blindaje contra títulos heredados
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }

        // ✅ Navegación correcta (sin warning / sin NavigationLink hidden)
        .navigationDestination(isPresented: $irAAsignacion) {
            AsignacionView(
                equipos: $equiposGenerados,
                ordenJugadores: ordenGlobal
            )
        }

        // Si vuelves atrás desde Asignación y quieres volver a girar:
        .onAppear {
            irAAsignacion = false
        }
    }

    // -------------------------------------------------
    // MARK: - Giro
    // -------------------------------------------------
    private func iniciarGiro() {
        mostrarBotonGirar = false
        mostrandoGenerando = true

        let giro = Double.random(in: 1080...1620)
        angulo += giro

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            generarEquiposYOrden()

            // ✅ Ir directo a Asignación solo si se generó bien
            if !equiposGenerados.isEmpty, !ordenGlobal.isEmpty {
                mostrandoGenerando = false
                irAAsignacion = true
            } else {
                // fallback: no se generó (caso raro), permitimos volver a girar
                mostrandoGenerando = false
                mostrarBotonGirar = true
            }
        }
    }

    // -------------------------------------------------
    // MARK: - Generación de Equipos y Orden
    // -------------------------------------------------
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
            grupos = [
                [mezclados[0], mezclados[1], mezclados[2], mezclados[3]],
                [mezclados[4], mezclados[5], mezclados[6], mezclados[7]]
            ]
        default:
            equiposGenerados = []
            ordenGlobal = []
            return
        }

        let empiezaPar = Bool.random()
        let tipos: [TipoEquipo] = [
            empiezaPar ? .par : .impar,
            empiezaPar ? .impar : .par
        ]

        var nuevos: [Equipo] = []

        for i in grupos.indices {
            let jugadoresObj = grupos[i].map { Jugador(nombre: $0) }
            nuevos.append(
                Equipo(
                    numero: i + 1,
                    nombre: "Equipo \(i + 1)",
                    tipo: tipos[i],
                    jugadores: jugadoresObj,
                    ordenJugadores: []
                )
            )
        }

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

        var turnoPar = empiezaPar
        var orden: [String] = []

        while !colaPar.isEmpty || !colaImpar.isEmpty {
            if turnoPar, !colaPar.isEmpty {
                orden.append(colaPar.removeFirst())
            } else if !turnoPar, !colaImpar.isEmpty {
                orden.append(colaImpar.removeFirst())
            } else if !colaPar.isEmpty {
                orden.append(colaPar.removeFirst())
            } else if !colaImpar.isEmpty {
                orden.append(colaImpar.removeFirst())
            }
            turnoPar.toggle()
        }

        ordenGlobal = orden

        let ranking = Dictionary(
            uniqueKeysWithValues: orden.enumerated().map { ($0.element, $0.offset + 1) }
        )

        for i in nuevos.indices {
            nuevos[i].ordenJugadores =
                nuevos[i].jugadores.map { ranking[$0.nombre] ?? 0 }
        }

        equiposGenerados = nuevos
    }
}

// -------------------------------------------------
// MARK: - Puntero
// -------------------------------------------------
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
