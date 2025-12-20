import SwiftUI

struct AsignacionView: View {

    @Binding var equipos: [Equipo]
    let ordenJugadores: [String]

    // ✅ Necesario para navegar a ScoresView (porque ScoresView exige turnos:)
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

                // ✅ #6 UX: agregar "Equipo"
                Text("Empieza la partida: Equipo \(turnos.empiezaPartida.titulo)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Tarjetas de equipos
                ForEach(equipos) { equipo in
                    VStack(alignment: .leading, spacing: 10) {

                        // ✅ #7/#8 UX: wording consistente
                        Text("Equipo #\(equipo.numero) — jugadores \(equipo.tipo.titulo)")
                            .font(.headline)
                            .foregroundColor(equipo.tipo == .par ? .blue : .red)

                        ForEach(Array(equipo.jugadores.enumerated()), id: \.element.id) { index, jugador in
                            HStack(spacing: 10) {
                                Text("\(equipo.ordenJugadores.indices.contains(index) ? equipo.ordenJugadores[index] : (index + 1))")
                                    .font(.caption.bold())
                                    .frame(width: 24, height: 24)
                                    .background(equipo.tipo == .par ? Color.blue : Color.red)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())

                                Text(jugador.nombre)
                                    .font(.body)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)

                                Spacer()
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(14)

                // ✅ #9 UX: botón que SI navega a ScoresView
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
