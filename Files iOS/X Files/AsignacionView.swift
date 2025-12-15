import SwiftUI

struct AsignacionView: View {

    @Binding var equipos: [Equipo]
    let ordenJugadores: [String]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Text("Asignación de Equipos")
                    .font(.title2.bold())
                    .padding(.top, 6)

                if equipos.count == 4 {
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
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

                // espacio extra para que el botón fijo no tape contenido
                Spacer().frame(height: 90)
            }
            .padding(.top, 4)
        }
        // Botón fijo abajo
        .safeAreaInset(edge: .bottom) {
            NavigationLink(
                destination: ScoresView(equipos: $equipos)
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
    }
}

// -------------------------------------------------------------
// MARK: - TARJETA DE EQUIPO
// -------------------------------------------------------------
extension AsignacionView {

    private func tarjetaEquipo(_ equipo: Equipo) -> some View {

        let color = (equipo.tipo == .par) ? Color.blue : Color.red

        // Orden ascendente por número global
        let paresOrdenados: [(numero: Int, nombre: String)] = zip(equipo.jugadores, equipo.ordenJugadores)
            .map { (jugador, num) in (numero: num, nombre: jugador.nombre) }
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

            ForEach(paresOrdenados, id: \.numero) { item in
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

// -------------------------------------------------------------
// MARK: - ORDEN DE JUGADORES
// -------------------------------------------------------------
extension AsignacionView {

    private var ordenJugadoresView: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text("Orden de Juego")
                .font(.headline)
                .padding(.horizontal)

            // ✅ Caso especial: 8 jugadores en 2 columnas (1-4 / 5-8)
            if ordenJugadores.count == 8 {
                let izq = Array(ordenJugadores.prefix(4))     // 1..4
                let der = Array(ordenJugadores.suffix(4))     // 5..8

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
                // Caso normal: 1 columna
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
