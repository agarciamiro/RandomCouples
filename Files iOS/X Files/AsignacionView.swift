import SwiftUI

struct AsignacionView: View {

    @Binding var equipos: [Equipo]
    let ordenJugadores: [String]

    // ✅ Necesario para poder navegar a ScoresView (porque ScoresView exige turnos:)
    @StateObject private var turnos: TurnosEngine

    // ✅ Init para crear el motor usando los equipos ya generados por RuletaView
    init(equipos: Binding<[Equipo]>, ordenJugadores: [String]) {
        self._equipos = equipos
        self.ordenJugadores = ordenJugadores
        self._turnos = StateObject(wrappedValue: TurnosEngine(equipos: equipos.wrappedValue))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Título
                VStack(spacing: 4) {
                    Text("Asignación Aleatoria de:")
                        .font(.title2.bold())

                    Text("signo · equipos · orden de jugadores")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 8)

                // ✅ Quién empieza (del motor real, no “equipos.first”)
                Text("Empieza la partida: Equipo \(turnos.empiezaPartida.titulo)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Tarjetas de equipos
                ForEach(equipos) { equipo in
                    VStack(alignment: .leading, spacing: 10) {

                        Text("Equipo #\(equipo.numero) jugadores \(equipo.tipo.titulo)")
                            .font(.headline)
                            .foregroundColor(equipo.tipo == .par ? .blue : .red)

                        ForEach(Array(equipo.jugadores.enumerated()), id: \.element.id) { index, jugador in
                            HStack {
                                Text("\(equipo.ordenJugadores[index])")
                                    .font(.caption.bold())
                                    .frame(width: 24, height: 24)
                                    .background(equipo.tipo == .par ? Color.blue : Color.red)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())

                                Text(jugador.nombre)
                                    .font(.body)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(14)
                }

                // Orden global
                VStack(spacing: 6) {
                    Text("Orden de jugadores")
                        .font(.headline)

                    ForEach(ordenJugadores.indices, id: \.self) { i in
                        Text("\(i + 1). \(ordenJugadores[i])")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)

                // ✅ NAVEGACIÓN CORRECTA A SCORESVIEW (con turnos:)
                NavigationLink {
                    ScoresView(
                        equipos: $equipos,
                        turnos: turnos,
                        ordenJugadores: ordenJugadores
                    )
                } label: {
                    Text("Agregar Puntajes")
                        .font(.title3.bold())
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Asignación")
        .navigationBarTitleDisplayMode(.inline)
    }
}
