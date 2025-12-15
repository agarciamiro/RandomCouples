import SwiftUI

struct ScoresView: View {

    @Binding var equipos: [Equipo]     // ✅ Binding (ya no se reinicia)

    private let minPuntaje = -99
    private let maxPuntaje = 99

    @Environment(\.dismiss) private var dismiss

    @State private var showResetAlert = false
    @State private var showNewGameAlert = false

    var body: some View {
        VStack(spacing: 16) {

            indicadorGanador

            ScrollView {
                VStack(spacing: 16) {
                    ForEach($equipos) { $equipo in
                        tarjetaEquipo($equipo)
                    }
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Puntajes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                Button {
                    showResetAlert = true
                } label: {
                    Text("Reset")
                }

                Button {
                    showNewGameAlert = true
                } label: {
                    Text("Nueva")
                }
            }
        }
        // ✅ Confirmación Reset
        .alert("Resetear puntajes", isPresented: $showResetAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetPuntajes()
            }
        } message: {
            Text("Esto pondrá todos los puntajes (equipo e individuales) en 0.")
        }
        // ✅ Confirmación Nueva Partida
        .alert("Nueva partida", isPresented: $showNewGameAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Nueva Partida", role: .destructive) {
                resetPuntajes()
                volverAlInicio()
            }
        } message: {
            Text("Se resetearán los puntajes y volverás a la pantalla inicial.")
        }
    }

    // --------------------------------------------------------------
    // MARK: - Acciones
    // --------------------------------------------------------------
    private func resetPuntajes() {
        for i in equipos.indices {
            equipos[i].puntajeActual = 0

            // por si puntajeIndividual viniera con tamaño distinto
            if equipos[i].puntajeIndividual.count != equipos[i].jugadores.count {
                equipos[i].puntajeIndividual = Array(repeating: 0, count: equipos[i].jugadores.count)
            } else {
                for j in equipos[i].puntajeIndividual.indices {
                    equipos[i].puntajeIndividual[j] = 0
                }
            }
        }
    }

    // Vuelve al inicio haciendo "pop" de pantallas
    private func volverAlInicio() {
        // Estamos en ScoresView (push desde AsignacionView). Con dos dismiss regresamos a Home.
        dismiss() // vuelve a AsignacionView
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            dismiss() // vuelve a HomeView
        }
    }
}

// --------------------------------------------------------------
// MARK: - Indicador dinámico
// --------------------------------------------------------------
extension ScoresView {

    private var indicadorGanador: some View {

        let totalPar = equipos
            .filter { $0.tipo == .par }
            .map { $0.puntajeActual }
            .reduce(0, +)

        let totalImpar = equipos
            .filter { $0.tipo == .impar }
            .map { $0.puntajeActual }
            .reduce(0, +)

        let texto: String
        let color: Color

        if totalPar > totalImpar {
            texto = "VA GANANDO PAR — \(totalPar) PUNTOS"
            color = .blue.opacity(0.7)
        } else if totalImpar > totalPar {
            texto = "VA GANANDO IMPAR — \(totalImpar) PUNTOS"
            color = .red.opacity(0.7)
        } else {
            texto = "VAN EMPATADOS — \(totalPar) PUNTOS"
            color = .gray.opacity(0.4)
        }

        return Text(texto)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(10)
            .padding(.bottom, 8)
    }
}

// --------------------------------------------------------------
// MARK: - Tarjeta de Equipo
// --------------------------------------------------------------
extension ScoresView {

    private func tarjetaEquipo(_ equipo: Binding<Equipo>) -> some View {

        let color = (equipo.wrappedValue.tipo == .par) ? Color.blue : Color.red

        return VStack(alignment: .leading, spacing: 10) {

            Text("Equipo #\(equipo.wrappedValue.numero)  \(equipo.wrappedValue.tipo.titulo)")
                .font(.title3.bold())
                .foregroundColor(color)

            ForEach(equipo.wrappedValue.jugadores.indices, id: \.self) { idx in

                let jugador = equipo.wrappedValue.jugadores[idx]

                HStack {
                    Text(jugador.nombre)
                        .font(.body)

                    Spacer()

                    Button("−") {
                        guard equipo.wrappedValue.puntajeIndividual[idx] > minPuntaje else { return }
                        guard equipo.wrappedValue.puntajeActual > minPuntaje else { return }

                        equipo.wrappedValue.puntajeIndividual[idx] -= 1
                        equipo.wrappedValue.puntajeActual -= 1
                    }

                    Text("\(equipo.wrappedValue.puntajeIndividual[idx])")
                        .frame(width: 30)

                    Button("+") {
                        guard equipo.wrappedValue.puntajeIndividual[idx] < maxPuntaje else { return }
                        guard equipo.wrappedValue.puntajeActual < maxPuntaje else { return }

                        equipo.wrappedValue.puntajeIndividual[idx] += 1
                        equipo.wrappedValue.puntajeActual += 1
                    }
                }
            }

            Divider()

            Text("Puntaje total: \(equipo.wrappedValue.puntajeActual)")
                .font(.headline)

        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}
