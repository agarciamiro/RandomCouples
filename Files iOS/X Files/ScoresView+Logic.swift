import SwiftUI

extension ScoresView {

    // MARK: - Picker Sheet (bolas normales)

    var pickerBolaSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {

                Text("Anotar bola metida")
                    .font(.headline)
                    .padding(.top, 8)

                Picker("", selection: $pickerTipoSeleccionado) {
                    Text("PAR").tag(TipoEquipo.par)
                    Text("IMPAR").tag(TipoEquipo.impar)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    let bolas = (pickerTipoSeleccionado == .par) ? bolasPar : bolasImpar
                    let metidas = (pickerTipoSeleccionado == .par) ? metidasPar : metidasImpar
                    let disponibles = bolas.filter { !metidas.contains($0) }

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(disponibles, id: \.self) { n in
                            Button {
                                registrarBola(numero: n)
                                mostrarPickerBola = false
                            } label: {
                                Circle()
                                    .fill((pickerTipoSeleccionado == .par ? Color.blue : Color.red).opacity(0.92))
                                    .frame(width: 46, height: 46)
                                    .overlay(Text("\(n)").font(.headline.bold()).foregroundColor(.white))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }

                Button("Cerrar") { mostrarPickerBola = false }
                    .font(.headline)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
        }
        // ✅ evita "ambiguous" en tu Xcode
        .presentationDetents(Set<PresentationDetent>([.medium, .large]))
        .onAppear {
            pickerTipoSeleccionado = turnos.turnoActual.tipo
        }
        .onChange(of: turnos.turnoActual) { _, _ in
            pickerTipoSeleccionado = turnos.turnoActual.tipo
        }
    }

    // MARK: - Registrar bola normal

    func registrarBola(numero: Int) {
        guard !bola8Resuelta else { return }

        let tipoBola: TipoEquipo
        if bolasPar.contains(numero) {
            tipoBola = .par
            if metidasPar.contains(numero) { return }
        } else if bolasImpar.contains(numero) {
            tipoBola = .impar
            if metidasImpar.contains(numero) { return }
        } else {
            return
        }

        let tipoTurno = turnos.turnoActual.tipo
        let anotoValida = (tipoBola == tipoTurno)
        let fueFalta = !anotoValida

        // 1) guardar
        if tipoBola == .par { metidasPar.insert(numero) } else { metidasImpar.insert(numero) }

        // 2) scorer SOLO si fue válida
        if anotoValida {
            scorerPorBola[numero] = turnos.turnoActual.jugadorNombre
        }

        // 3) recalcular
        sincronizarTotales()

        // 4) turnos (Auto)
        if turnos.modoAutoAvance {
            turnos.registrarTiro(anotoBolaValida: anotoValida, fueFalta: fueFalta)
        }
    }

    func desmarcarBola(numero: Int) {
        if metidasPar.contains(numero) { metidasPar.remove(numero) }
        if metidasImpar.contains(numero) { metidasImpar.remove(numero) }
        scorerPorBola.removeValue(forKey: numero)
        sincronizarTotales()
    }

    // MARK: - Totales

    func totalBolas(_ tipo: TipoEquipo) -> Int {
        (tipo == .par) ? metidasPar.count : metidasImpar.count
    }

    func totalFinal(_ tipo: TipoEquipo) -> Int {
        if bola8Resuelta, let ganador = ganadorPor8 {
            if ganador == tipo { return 8 } // el ganador “cierra en 8”
            return totalBolas(tipo)
        }
        return totalBolas(tipo)
    }

    // MARK: - Sincronizar puntajes (1 fuente de verdad)

    func sincronizarTotales() {

        // 1) reset equipos
        for i in equipos.indices {
            equipos[i].puntajeActual = 0
            if equipos[i].puntajeIndividual.count != equipos[i].jugadores.count {
                equipos[i].puntajeIndividual = Array(repeating: 0, count: equipos[i].jugadores.count)
            } else {
                for j in equipos[i].puntajeIndividual.indices { equipos[i].puntajeIndividual[j] = 0 }
            }
        }

        // 2) set total por tipo (y si ya hubo 8, forzar final)
        for i in equipos.indices {
            let tipo = equipos[i].tipo
            equipos[i].puntajeActual = bola8Resuelta ? totalFinal(tipo) : totalBolas(tipo)
        }

        // 3) puntos individuales por bolas válidas
        for (bola, scorer) in scorerPorBola {
            if let (eIdx, jIdx) = encontrarJugador(scorer) {
                asegurarTamanosIndividual(enEquipo: eIdx)
                equipos[eIdx].puntajeIndividual[jIdx] += 1
            }
        }

        // 4) punto individual por 8 SOLO si fue victoria “limpia”
        if bola8Resuelta,
           let ganador = ganadorPor8,
           let scorer8 = bola8ScorerNombre,
           !bola8FueAdelantada,
           !bola8FueIncorrecta
        {
            // sumar 1 al scorer8 (ya está contemplado en totalFinal del equipo por UI)
            if let (eIdx, jIdx) = encontrarJugador(scorer8),
               equipos[eIdx].tipo == ganador {
                asegurarTamanosIndividual(enEquipo: eIdx)
                equipos[eIdx].puntajeIndividual[jIdx] += 1
            }
        }
    }

    // MARK: - Reset

    func resetBolas() {
        metidasPar.removeAll()
        metidasImpar.removeAll()
        scorerPorBola.removeAll()

        bola8Resuelta = false
        ganadorPor8 = nil
        bola8ScorerNombre = nil
        bola8FueAdelantada = false
        bola8FueIncorrecta = false
        troneraCantada = 1

        sincronizarTotales()
    }

    func resetPuntajesSolo() {
        for i in equipos.indices {
            equipos[i].puntajeActual = 0
            if equipos[i].puntajeIndividual.count != equipos[i].jugadores.count {
                equipos[i].puntajeIndividual = Array(repeating: 0, count: equipos[i].jugadores.count)
            } else {
                for j in equipos[i].puntajeIndividual.indices { equipos[i].puntajeIndividual[j] = 0 }
            }
        }
    }

    func resetTodo() {
        resetBolas()
    }

    // MARK: - Helpers

    func encontrarJugador(_ nombre: String) -> (Int, Int)? {
        for eIdx in equipos.indices {
            if let jIdx = equipos[eIdx].jugadores.firstIndex(where: { $0.nombre == nombre }) {
                return (eIdx, jIdx)
            }
        }
        return nil
    }

    func asegurarTamanosIndividual(enEquipo idx: Int) {
        if equipos[idx].puntajeIndividual.count != equipos[idx].jugadores.count {
            equipos[idx].puntajeIndividual = Array(repeating: 0, count: equipos[idx].jugadores.count)
        }
    }
}
