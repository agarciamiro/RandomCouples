import SwiftUI

extension ScoresView {

    // MARK: - Banner

    var bannerEstadoPartida: some View {
        Text(textoBannerVivo)
            .font(.subheadline.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.green.opacity(0.78))
            .cornerRadius(14)
    }

    var textoBannerVivo: String {
        if bola8Resuelta, ganadorPor8 != nil { return textoBannerFinal }

        let p = metidasPar.count
        let i = metidasImpar.count

        // ✅ Nunca mostrar “8 bolas” sin registrar la 8
        if p == 7 && i == 7 { return "AMBOS A 7 — SE DEFINE CON LA 8" }
        if p == 7 { return "PAR YA PUEDE CANTAR LA 8 — PAR 7 vs IMPAR \(i)" }
        if i == 7 { return "IMPAR YA PUEDE CANTAR LA 8 — IMPAR 7 vs PAR \(p)" }

        if p == i { return "VAN EMPATANDO — \(p) BOLAS" }
        if p > i { return "VA GANANDO PAR — \(p) BOLAS" }
        return "VA GANANDO IMPAR — \(i) BOLAS"
    }

    var textoBannerFinal: String {
        guard let ganador = ganadorPor8 else { return "—" }

        if bola8FueAdelantada {
            return "🏆 GANÓ \(ganador.titulo) — 8 ADELANTADA"
        }
        if bola8FueIncorrecta {
            return "🏆 GANÓ \(ganador.titulo) — TRONERA INCORRECTA"
        }

        // Caso normal
        return ganador == .par ? "🏆 GANÓ PAR 8" : "🏆 GANÓ IMPAR 8"
    }

    // MARK: - Turnos

    var cardTurnos: some View {
        VStack(spacing: 8) {

            HStack(spacing: 10) {
                Text("Empieza: \(turnos.empiezaPartida.titulo)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Toggle("Auto", isOn: $turnos.modoAutoAvance)
                    .labelsHidden()

                Button {
                    turnos.siguienteTurno()
                } label: {
                    Text("Siguiente Turno")
                        .font(.subheadline.bold())
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            HStack(spacing: 10) {
                Circle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 18, height: 18)
                    .overlay(Text("8").font(.caption2.bold()).foregroundColor(.white))
                    .opacity(turnos.bolaEnManoParaSiguiente ? 1 : 0.30)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Turno")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(turnos.turnoActual.tipo.titulo) — \(turnos.turnoActual.jugadorNombre)")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Text("Equipo #\(turnos.turnoActual.equipoNumero)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if turnos.bolaEnManoParaSiguiente {
                    Text("Bola en mano")
                        .font(.caption.bold())
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Color.orange.opacity(0.22))
                        .cornerRadius(10)
                }
            }

            Button {
                // Falta: NO suma, y pasa turno (siempre)
                turnos.registrarTiro(anotoBolaValida: false, fueFalta: true)
            } label: {
                Text("Falta: Blanca / Bola rival")
                    .font(.subheadline.bold())
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.18))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - Registro Bolas + Bola 8

    var cardRegistroBolas: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("Registro de Bolas")
                    .font(.headline)

                Spacer()

                Button("Reset") { resetBolas() }
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PAR")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                    gridBolas(bolasPar, tipo: .par)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("IMPAR")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    gridBolas(bolasImpar, tipo: .impar)
                }
            }

            Divider().padding(.top, 2)

            // ✅ Mostrar “cantar la 8”
            if !bola8Resuelta, (metidasPar.count == 7 || metidasImpar.count == 7) {
                let t =
                (metidasPar.count == 7 && metidasImpar.count == 7)
                ? "🎱 Ambos ya pueden cantar la 8"
                : (metidasPar.count == 7 ? "🎱 PAR ya puede cantar la 8" : "🎱 IMPAR ya puede cantar la 8")

                Text(t)
                    .font(.subheadline.bold())
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.18))
                    .cornerRadius(12)
            }

            // ✅ Botón 8 SOLO si alguien llegó a 7
            if !bola8Resuelta && (metidasPar.count == 7 || metidasImpar.count == 7) {

                let colorFondo: Color = {
                    if metidasPar.count == 7 && metidasImpar.count < 7 { return .blue }
                    if metidasImpar.count == 7 && metidasPar.count < 7 { return .red }
                    return .green
                }()

                Button {
                    abrirRegistroBola8()
                } label: {
                    Text("🎱 Registrar bola 8 (turno: \(turnos.turnoActual.tipo.titulo))")
                        .font(.subheadline.bold())
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(colorFondo.opacity(0.92))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            Text("Tip: Las bolas normales se anotan con el “+” del jugador en turno.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    func gridBolas(_ bolas: [Int], tipo: TipoEquipo) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(bolas, id: \.self) { n in
                bolaChip(numero: n, tipo: tipo)
            }
        }
    }

    func bolaChip(numero: Int, tipo: TipoEquipo) -> some View {
        let marcada = (tipo == .par) ? metidasPar.contains(numero) : metidasImpar.contains(numero)
        let color: Color = (tipo == .par) ? .blue : .red

        return Button {
            if marcada { desmarcarBola(numero: numero) }
        } label: {
            Circle()
                .fill(marcada ? color.opacity(0.92) : Color.gray.opacity(0.14))
                .frame(width: 34, height: 34)
                .overlay(
                    Text("\(numero)")
                        .font(.caption.bold())
                        .foregroundColor(marcada ? .white : .primary)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tarjeta equipo (+ solo turno)

    func esJugadorDeTurno(_ nombre: String) -> Bool {
        nombre == turnos.turnoActual.jugadorNombre
    }

    func tarjetaEquipo(_ equipo: Binding<Equipo>) -> some View {

        let color: Color = (equipo.wrappedValue.tipo == .par) ? .blue : .red

        return VStack(alignment: .leading, spacing: 8) {

            HStack {
                Text("Equipo #\(equipo.wrappedValue.numero)  \(equipo.wrappedValue.tipo.titulo)")
                    .font(.subheadline.bold())
                    .foregroundColor(color)

                Spacer()

                Text("Total: \(equipo.wrappedValue.puntajeActual)")
                    .font(.subheadline.bold())
            }

            Divider()

            ForEach(equipo.wrappedValue.jugadores.indices, id: \.self) { idx in
                let nombre = equipo.wrappedValue.jugadores[idx].nombre
                let indiv = (idx < equipo.wrappedValue.puntajeIndividual.count) ? equipo.wrappedValue.puntajeIndividual[idx] : 0
                let enTurno = esJugadorDeTurno(nombre)

                HStack(spacing: 10) {
                    Text(nombre)
                        .font(.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.80)

                    Spacer()

                    Text("\(indiv)")
                        .font(.subheadline.bold())
                        .frame(width: 30, alignment: .trailing)

                    if enTurno {
                        Button {
                            pickerTipoSeleccionado = turnos.turnoActual.tipo
                            DispatchQueue.main.async { mostrarPickerBola = true }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}
