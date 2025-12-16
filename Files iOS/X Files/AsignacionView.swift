import SwiftUI

struct AsignacionView: View {

    @Binding var equipos: [Equipo]
    @Binding var ordenJugadores: [String]
    @Binding var empiezaTipo: TipoEquipo

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Text("Asignación de Equipos")
                    .font(.title2.bold())
                    .padding(.top, 6)

                Text("Empieza la partida: \(empiezaTipo == .par ? "PAR" : "IMPAR")")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)

                if equipos.count == 4 {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(equipos) { equipo in
                            tarjetaEquipo(equipo)
                        }
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 12) {
                        ForEach(equipos) { equipo in
                            tarjetaEquipo(equipo)
                                .padding(.horizontal)
                        }
                    }
                }

                Divider().padding(.vertical, 6)

                ordenJugadoresView

                Spacer().frame(height: 90)
            }
            .padding(.top, 4)
        }
        .safeAreaInset(edge: .bottom) {
            NavigationLink(
                destination: ScoresView(
                    equipos: $equipos,
                    empiezaTipo: $empiezaTipo,
                    ordenJugadores: $ordenJugadores
                )
            ) {
                Text("Agregar Puntajes")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
            }
            .background(.ultraThinMaterial)
        }
        .navigationBarBackButtonHidden(true)
    }
}

extension AsignacionView {

    private func tarjetaEquipo(_ equipo: Equipo) -> some View {

        let color = (equipo.tipo == .par) ? Color.blue : Color.red

        let itemsOrdenados: [(numero: Int, nombre: String, puntos: Int)] = equipo.jugadores.indices
            .map { idx in
                let numero = (idx < equipo.ordenJugadores.count) ? equipo.ordenJugadores[idx] : 0
                let nombre = equipo.jugadores[idx].nombre
                let puntos = (idx < equipo.puntajeIndividual.count) ? equipo.puntajeIndividual[idx] : 0
                return (numero: numero, nombre: nombre, puntos: puntos)
            }
            .sorted { $0.numero < $1.numero }

        return VStack(alignment: .leading, spacing: 8) {

            HStack(alignment: .firstTextBaseline) {
                Text("Equipo #\(equipo.numero)  \(equipo.tipo.titulo)")
                    .font(.subheadline.bold())
                    .foregroundColor(color)

                Spacer()

                HStack(spacing: 6) {
                    Text("Puntaje Acumulado")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("\(equipo.puntajeActual)")
                        .font(.subheadline.bold())
                        .foregroundColor(color)
                }
            }

            HStack {
                Spacer()
                Text("Individual")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ForEach(itemsOrdenados, id: \.numero) { item in
                HStack(spacing: 10) {

                    Circle()
                        .fill(color.opacity(0.85))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text("\(item.numero)")
                                .foregroundColor(.white)
                                .font(.caption.bold())
                        )

                    Text(item.nombre)
                        .font(.subheadline)

                    Spacer()

                    Text("\(item.puntos)")
                        .font(.subheadline.bold())
                        .frame(minWidth: 30, alignment: .trailing)
                        .foregroundColor(.primary)
                }
            }

        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 3)
    }
}

extension AsignacionView {

    private var ordenJugadoresView: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Orden de Juego")
                .font(.headline)
                .padding(.horizontal)

            if ordenJugadores.count == 8 {
                let izq = Array(ordenJugadores.prefix(4))
                let der = Array(ordenJugadores.suffix(4))

                HStack(alignment: .top, spacing: 28) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(izq.indices, id: \.self) { i in
                            Text("\(i + 1). \(izq[i])")
                                .font(.subheadline)
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(der.indices, id: \.self) { i in
                            Text("\(i + 5). \(der[i])")
                                .font(.subheadline)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal)
            } else {
                ForEach(ordenJugadores.indices, id: \.self) { idx in
                    Text("\(idx + 1). \(ordenJugadores[idx])")
                        .font(.subheadline)
                        .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 6)
    }
}
