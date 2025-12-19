import SwiftUI

extension ScoresView {

    // MARK: - Abrir registro bola 8

    func abrirRegistroBola8() {
        troneraCantada = 1
        mostrarSheetBola8 = true
    }

    // MARK: - Sheet Bola 8

    var bola8Sheet: some View {
        NavigationStack {
            VStack(spacing: 14) {

                HStack {
                    Text("🎱 Registrar bola 8")
                        .font(.headline.bold())
                    Spacer()
                }

                Text("Turno actual: \(turnos.turnoActual.tipo.titulo) — \(turnos.turnoActual.jugadorNombre)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tronera cantada")
                        .font(.subheadline.bold())

                    Picker("Tronera", selection: $troneraCantada) {
                        ForEach(1...6, id: \.self) { n in
                            Text("Tronera \(n)").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(12)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(14)

                Button {
                    resolverBola8(fueEnTroneraCantada: true)
                    mostrarSheetBola8 = false
                } label: {
                    Text("✅ Entró en la tronera cantada")
                        .font(.subheadline.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.90))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button {
                    resolverBola8(fueEnTroneraCantada: false)
                    mostrarSheetBola8 = false
                } label: {
                    Text("❌ Entró en otra tronera")
                        .font(.subheadline.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.90))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button {
                    mostrarSheetBola8 = false
                } label: {
                    Text("Cancelar")
                        .font(.subheadline.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.18))
                        .foregroundColor(.primary)
                        .cornerRadius(14)
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        .presentationDetents(Set<PresentationDetent>([.medium, .large]))
    }

    // MARK: - Resolver lógica bola 8 (según turno)

    func resolverBola8(fueEnTroneraCantada: Bool) {
        guard !bola8Resuelta else { return }

        let tipoTirador = turnos.turnoActual.tipo
        let tiradorTiene7 = (tipoTirador == .par) ? (metidasPar.count == 7) : (metidasImpar.count == 7)

        bola8Resuelta = true
        bola8FueAdelantada = false
        bola8FueIncorrecta = false

        if !tiradorTiene7 {
            // 8 adelantada -> gana el otro
            ganadorPor8 = (tipoTirador == .par) ? .impar : .par
            bola8FueAdelantada = true
            bola8ScorerNombre = nil
        } else if !fueEnTroneraCantada {
            // tronera incorrecta -> gana el otro
            ganadorPor8 = (tipoTirador == .par) ? .impar : .par
            bola8FueIncorrecta = true
            bola8ScorerNombre = nil
        } else {
            // victoria limpia
            ganadorPor8 = tipoTirador
            bola8ScorerNombre = turnos.turnoActual.jugadorNombre
        }

        sincronizarTotales()

        // ✅ automático: muestra resultados
        accionPendiente = .reset
        mostrarResultados = true
    }
}


// MARK: - Resultados Sheet (sin scroll)
struct ResultadosSheet: View {

    let textoBannerFinal: String
    let equipos: [Equipo]
    let accion: ScoresView.AccionPostResultados

    let onResetConfirmado: () -> Void
    let onNuevaConfirmado: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {

                HStack {
                    Text("Resultados")
                        .font(.headline.bold())
                    Spacer()
                }

                Text(textoBannerFinal)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color.green.opacity(0.78))
                    .cornerRadius(14)

                VStack(spacing: 8) {
                    ForEach(equipos) { eq in
                        let color: Color = (eq.tipo == .par) ? .blue : .red

                        VStack(alignment: .leading, spacing: 6) {

                            HStack {
                                Text("Equipo #\(eq.numero)  \(eq.tipo.titulo)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(color)

                                Spacer()

                                Text("Total: \(eq.puntajeActual)")
                                    .font(.subheadline.bold())
                            }

                            Divider()

                            ForEach(eq.jugadores.indices, id: \.self) { idx in
                                let nombre = eq.jugadores[idx].nombre
                                let puntos = (idx < eq.puntajeIndividual.count) ? eq.puntajeIndividual[idx] : 0

                                HStack {
                                    Text(nombre)
                                        .font(.caption2)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                    Spacer()
                                    Text("\(puntos)")
                                        .font(.caption.bold())
                                }
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }

                Button {
                    switch accion {
                    case .reset: onResetConfirmado()
                    case .nueva: onNuevaConfirmado()
                    }
                    dismiss()
                } label: {
                    Text(accion == .reset ? "Nueva Partida" : "Ir al Inicio")
                        .font(.subheadline.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(accion == .reset ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Cancelar")
                        .font(.subheadline.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.18))
                        .foregroundColor(.primary)
                        .cornerRadius(14)
                }
            }
            .padding()
        }
        .presentationDetents(Set<PresentationDetent>([.large]))
    }
}
