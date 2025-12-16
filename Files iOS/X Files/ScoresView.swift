import SwiftUI

struct ScoresView: View {

    @Binding var equipos: [Equipo]

    private let minPuntaje = -99
    private let maxPuntaje = 99

    enum AccionPostResultados {
        case reset
        case nueva
    }

    @State private var mostrarResultados = false
    @State private var accionPendiente: AccionPostResultados = .reset

    // ✅ Ir al Home de forma infalible
    @State private var mostrarHome = false

    // ✅ Bandera para abrir Home SOLO cuando el sheet ya se cerró
    @State private var irAlHomePendiente = false

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
        .background(Color(.systemBackground)) // ✅ evita transparencias
        .navigationTitle("Puntajes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                Button {
                    accionPendiente = .reset
                    mostrarResultados = true
                } label: {
                    Text("Nueva")
                }

                Button {
                    accionPendiente = .nueva
                    mostrarResultados = true
                } label: {
                    Text("Finalizar")
                }
            }
        }
        .sheet(isPresented: $mostrarResultados) {
            ResultadosSheet(
                equipos: equipos,
                accion: accionPendiente,
                onResetConfirmado: {
                    resetPuntajes()
                    mostrarResultados = false
                },
                onNuevaConfirmado: {
                    resetPuntajes()
                    irAlHomePendiente = true
                    mostrarResultados = false
                }
            )
        }
        // ✅ Cuando el sheet ya se cerró, recién abrimos el Home
        .onChange(of: mostrarResultados) { _, mostrando in
            if !mostrando && irAlHomePendiente {
                irAlHomePendiente = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    mostrarHome = true
                }
            }
        }
        // ✅ Home “pantalla 1” sin depender del stack anterior (y SIN transparencias)
        .fullScreenCover(isPresented: $mostrarHome) {
            NavigationStack {
                ZStack {
                    Color(.systemBackground)
                        .ignoresSafeArea()   // ✅ tapa TODO, cero mezcla

                    HomeView()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancelar") {
                            mostrarHome = false
                        }
                        .font(.footnote)
                    }
                }
            }
            .interactiveDismissDisabled(true)
        }
    }

    // --------------------------------------------------------------
    // MARK: - Acciones
    // --------------------------------------------------------------
    private func resetPuntajes() {
        for i in equipos.indices {
            equipos[i].puntajeActual = 0

            if equipos[i].puntajeIndividual.count != equipos[i].jugadores.count {
                equipos[i].puntajeIndividual = Array(repeating: 0, count: equipos[i].jugadores.count)
            } else {
                for j in equipos[i].puntajeIndividual.indices {
                    equipos[i].puntajeIndividual[j] = 0
                }
            }
        }
    }
}

// --------------------------------------------------------------
// MARK: - Indicador dinámico (SIEMPRE fondo VERDE)
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

        if totalPar > totalImpar {
            texto = "GANÓ PAR — \(totalPar) PUNTOS"
        } else if totalImpar > totalPar {
            texto = "GANÓ IMPAR — \(totalImpar) PUNTOS"
        } else {
            texto = "EMPATE — \(totalPar) PUNTOS"
        }

        return Text(texto)
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green.opacity(0.75))
            .cornerRadius(10)
            .padding(.bottom, 8)
    }
}

// --------------------------------------------------------------
// MARK: - Tarjeta de Equipo (puntajes en vivo)
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

// --------------------------------------------------------------
// MARK: - Sheet de Resultados (FINAL por equipo + jugador)
// --------------------------------------------------------------
private struct ResultadosSheet: View {

    let equipos: [Equipo]
    let accion: ScoresView.AccionPostResultados

    let onResetConfirmado: () -> Void
    let onNuevaConfirmado: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var totalPar: Int {
        equipos.filter { $0.tipo == .par }.map { $0.puntajeActual }.reduce(0, +)
    }

    private var totalImpar: Int {
        equipos.filter { $0.tipo == .impar }.map { $0.puntajeActual }.reduce(0, +)
    }

    private var tituloGanador: String {
        if totalPar > totalImpar { return "🏆 Ganó PAR" }
        if totalImpar > totalPar { return "🏆 Ganó IMPAR" }
        return "🤝 Empate"
    }

    private var subtitulo: String {
        "PAR: \(totalPar)  —  IMPAR: \(totalImpar)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {

                    HStack {
                        Text("Resultados Finales")
                            .font(.title2.bold())
                        Spacer()
                    }

                    // ✅ Banner RESULTADOS en VERDE (siempre)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(tituloGanador)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(subtitulo)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.95))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.green.opacity(0.75))
                    .cornerRadius(14)

                    VStack(spacing: 12) {
                        ForEach(equipos) { eq in
                            let color: Color = (eq.tipo == .par) ? .blue : .red

                            VStack(alignment: .leading, spacing: 10) {

                                HStack {
                                    Text("Equipo #\(eq.numero)  \(eq.tipo.titulo)")
                                        .font(.headline)
                                        .foregroundColor(color)

                                    Spacer()

                                    Text("Total: \(eq.puntajeActual)")
                                        .font(.headline)
                                }

                                Divider()

                                ForEach(eq.jugadores.indices, id: \.self) { idx in
                                    let nombre = eq.jugadores[idx].nombre
                                    let puntos = (idx < eq.puntajeIndividual.count) ? eq.puntajeIndividual[idx] : 0

                                    HStack {
                                        Text(nombre)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(puntos)")
                                            .font(.subheadline.bold())
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                    }

                    Spacer().frame(height: 10)

                    Button {
                        switch accion {
                        case .reset:
                            onResetConfirmado()
                        case .nueva:
                            onNuevaConfirmado()
                        }
                        dismiss()
                    } label: {
                        Text(accion == .reset ? "Nueva Partida" : "Ir al Inicio de la APP")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(accion == .reset ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Cancelar")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(14)
                    }
                }
                .padding()
            }
        }
    }
}
