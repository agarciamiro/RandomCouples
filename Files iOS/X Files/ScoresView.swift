import SwiftUI

// =====================================================
// MARK: - ScoresView (UI + Lógica + Bola 8 + Resultados)
// =====================================================

struct ScoresView: View {

    @Binding var equipos: [Equipo]

    // Motor de turnos
    @StateObject var turnos: TurnosEngine

    // Reglas PAR/IMPAR
    let bolasPar = [2, 4, 6, 10, 12, 14, 15]
    let bolasImpar = [1, 3, 5, 7, 9, 11, 13]

    // Registro real
    @State private var metidasPar: Set<Int> = []
    @State private var metidasImpar: Set<Int> = []

    // Scorer por bola (solo si fue válida para el tirador)
    @State private var scorerPorBola: [Int: String] = [:]

    // Picker bolas
    @State private var mostrarPickerBola = false
    @State private var pickerTipoSeleccionado: TipoEquipo = .par

    // Bola 8
    @State private var mostrarSheetBola8 = false
    @State private var bola8Resuelta = false
    @State private var ganadorPor8: TipoEquipo? = nil
    @State private var bola8ScorerNombre: String? = nil
    @State private var bola8FueAdelantada = false
    @State private var bola8FueIncorrecta = false
    @State private var troneraCantada: Int = 1

    // Resultados
    enum AccionPostResultados { case reset, nueva }
    @State private var mostrarResultados = false
    @State private var accionPendiente: AccionPostResultados = .reset

    // Volver al inicio (sin depender de HomeView)
    @State private var mostrarInicio = false
    @State private var irAlInicioPendiente = false

    // MARK: - INITS (compat)
    init(equipos: Binding<[Equipo]>) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: TurnosEngine(equipos: equipos.wrappedValue))
    }

    init(equipos: Binding<[Equipo]>, turnos: TurnosEngine, ordenJugadores: [String] = []) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: turnos)
    }

    init(equipos: Binding<[Equipo]>, _ turnos: TurnosEngine, _ ordenJugadores: [String]) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: turnos)
    }

    // MARK: - BODY
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                bannerEstadoPartida

                cardTurnos

                cardRegistroBolas

                ForEach($equipos) { $equipo in
                    tarjetaEquipo($equipo)
                }

                Spacer().frame(height: 18)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Puntajes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                Button {
                    sincronizarTotales()
                    accionPendiente = .reset
                    mostrarResultados = true
                } label: { Text("Nueva") }

                Button {
                    sincronizarTotales()
                    accionPendiente = .nueva
                    mostrarResultados = true
                } label: { Text("Finalizar") }
            }
        }
        .sheet(isPresented: $mostrarPickerBola) { pickerBolaSheet }
        .sheet(isPresented: $mostrarSheetBola8) { bola8Sheet }
        .sheet(isPresented: $mostrarResultados) {
            ResultadosSheet(
                textoBannerFinal: textoBannerFinal,
                equipos: equipos,
                accion: accionPendiente,
                onResetConfirmado: {
                    resetTodo()
                    mostrarResultados = false
                },
                onNuevaConfirmado: {
                    resetTodo()
                    irAlInicioPendiente = true
                    mostrarResultados = false
                }
            )
        }
        .onChange(of: mostrarResultados) { _, mostrando in
            if !mostrando && irAlInicioPendiente {
                irAlInicioPendiente = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    mostrarInicio = true
                }
            }
        }
        .fullScreenCover(isPresented: $mostrarInicio) {
            NavigationStack {
                ContentView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Cerrar") { mostrarInicio = false }
                                .font(.footnote)
                        }
                    }
            }
            .interactiveDismissDisabled(true)
        }
        .onAppear { resetPuntajesSolo() }
    }
}

// =====================================================
// MARK: - UI (Banners / Cards / Tarjetas)
// =====================================================

extension ScoresView {

    func nombreTipo(_ tipo: TipoEquipo) -> String {
        switch tipo {
        case .par: return "PAR"
        case .impar: return "IMPAR"
        }
    }

    func colorTipo(_ tipo: TipoEquipo) -> Color {
        switch tipo {
        case .par: return .blue
        case .impar: return .red
        }
    }

    var bannerEstadoPartida: some View {
        let par = totalFinal(.par)
        let impar = totalFinal(.impar)

        let texto: String
        if bola8Resuelta, let g = ganadorPor8 {
            texto = "GANÓ \(nombreTipo(g)) 8"
        } else {
            texto = "PAR \(par)  •  IMPAR \(impar)"
        }

        return Text(texto)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.12))
            .cornerRadius(14)
    }

    var cardTurnos: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Turno")
                    .font(.headline)
                Spacer()
                Text(nombreTipo(turnos.turnoActual.tipo))
                    .font(.subheadline.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(colorTipo(turnos.turnoActual.tipo).opacity(0.15))
                    .cornerRadius(10)
            }

            HStack(spacing: 10) {
                Text("Jugador:")
                    .foregroundColor(.secondary)
                Text(turnos.turnoActual.jugadorNombre)
                    .font(.headline)

                // "+" solo para el jugador en turno (abre picker)
                Spacer()
                Button {
                    mostrarPickerBola = true
                } label: {
                    Text("+")
                        .font(.headline.bold())
                        .frame(width: 36, height: 28)
                        .background(colorTipo(turnos.turnoActual.tipo).opacity(0.18))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Anotar bola")
            }
        }
        .padding(14)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }

    var cardRegistroBolas: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Registro de bolas")
                .font(.headline)

            HStack(spacing: 10) {
                Button {
                    mostrarPickerBola = true
                } label: {
                    Text("Anotar bola")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(12)
                }

                Button {
                    mostrarSheetBola8 = true
                } label: {
                    Text("Bola 8")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.12))
                        .cornerRadius(12)
                }
            }

            HStack {
                Text("PAR: \(totalFinal(.par))")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12))
                    .cornerRadius(10)

                Text("IMPAR: \(totalFinal(.impar))")
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(10)

                Spacer()
            }
        }
        .padding(14)
        .background(Color.gray.opacity(0.08))
        .cornerRadius(16)
    }

    func tarjetaEquipo(_ equipo: Binding<Equipo>) -> some View {
        let tipo = equipo.wrappedValue.tipo

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Equipo \(nombreTipo(tipo))")
                    .font(.headline)
                Spacer()
                Text("\(equipo.wrappedValue.puntajeActual)")
                    .font(.title3.bold())
                    .foregroundColor(colorTipo(tipo))
            }

            ForEach(Array(equipo.wrappedValue.jugadores.enumerated()), id: \.offset) { idx, jugador in
                HStack {
                    Text(jugador.nombre)
                    Spacer()
                    let ind = (idx < equipo.wrappedValue.puntajeIndividual.count)
                    ? equipo.wrappedValue.puntajeIndividual[idx]
                    : 0
                    Text("\(ind)")
                        .foregroundColor(.secondary)
                }
                .font(.subheadline)
            }
        }
        .padding(14)
        .background(colorTipo(tipo).opacity(0.08))
        .cornerRadius(16)
    }
}

// =====================================================
// MARK: - Resultados (ganador + texto final)
// =====================================================

extension ScoresView {

    private var totalPar: Int { metidasPar.count }
    private var totalImpar: Int { metidasImpar.count }

    // Ganador “duro”:
    // - Si hubo bola 8 resuelta, ya hay ganador.
    // - Si no, el primero que llega a 8 bolas gana.
    private var ganadorActual: TipoEquipo? {
        if bola8Resuelta, let g = ganadorPor8 { return g }
        if totalPar >= 8 { return .par }
        if totalImpar >= 8 { return .impar }
        return nil
    }

    // Texto final para ResultadosSheet (NO debe decir empate si 8 vs 7)
    var textoBannerFinal: String {
        let par = totalFinal(.par)
        let impar = totalFinal(.impar)

        if let g = ganadorActual {
            if bola8Resuelta && bola8FueAdelantada {
                return "GANÓ \(nombreTipo(g)) (BOLA 8 ADELANTADA)"
            }
            if bola8Resuelta && bola8FueIncorrecta {
                return "GANÓ \(nombreTipo(g)) (BOLA 8 INCORRECTA)"
            }
            return "GANÓ \(nombreTipo(g)) (\(par)-\(impar))"
        }

        if par == impar { return "EMPATE (\(par)-\(impar))" }
        return "GANA \(par > impar ? "PAR" : "IMPAR") (\(par)-\(impar))"
    }
}

// =====================================================
// MARK: - Sheets (Picker bolas + Bola 8)
// =====================================================

extension ScoresView {

    // Picker Sheet (bolas normales)
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
        .presentationDetents(Set<PresentationDetent>([.medium, .large]))
        .onAppear { pickerTipoSeleccionado = turnos.turnoActual.tipo }
        .onChange(of: turnos.turnoActual) { _, _ in
            pickerTipoSeleccionado = turnos.turnoActual.tipo
        }
    }

    // Sheet Bola 8
    var bola8Sheet: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text("Bola 8")
                    .font(.title3.bold())
                    .padding(.top, 8)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Jugador en turno: \(turnos.turnoActual.jugadorNombre)")
                        .font(.headline)

                    Text("Equipo: \(nombreTipo(turnos.turnoActual.tipo))")
                        .foregroundColor(.secondary)

                    Divider()

                    Text("Tronera cantada")
                        .font(.headline)

                    Picker("Tronera", selection: $troneraCantada) {
                        ForEach(1...6, id: \.self) { n in
                            Text("Tronera \(n)").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)

                    Divider()

                    Toggle("Bola 8 adelantada (pierde el tirador)", isOn: $bola8FueAdelantada)
                    Toggle("Bola 8 incorrecta (pierde el tirador)", isOn: $bola8FueIncorrecta)
                }
                .padding(12)
                .background(Color.gray.opacity(0.10))
                .cornerRadius(12)

                Button {
                    confirmarBola8()
                    mostrarSheetBola8 = false
                    mostrarResultados = true
                } label: {
                    Text("Confirmar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.12))
                        .cornerRadius(12)
                }

                Button("Cancelar") {
                    mostrarSheetBola8 = false
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal)
        }
        .presentationDetents(Set<PresentationDetent>([.medium, .large]))
    }
}

// =====================================================
// MARK: - Lógica (registrar, sincronizar, reset, helpers)
// =====================================================

extension ScoresView {

    // Registrar bola normal
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

    // Bola 8
    func confirmarBola8() {
        guard !bola8Resuelta else { return }

        bola8Resuelta = true
        bola8ScorerNombre = turnos.turnoActual.jugadorNombre

        // Si adelantada o incorrecta => gana el otro equipo
        if bola8FueAdelantada || bola8FueIncorrecta {
            ganadorPor8 = (turnos.turnoActual.tipo == .par) ? .impar : .par
        } else {
            // “limpia”
            ganadorPor8 = turnos.turnoActual.tipo
        }

        sincronizarTotales()
    }

    // Sincronizar puntajes (1 fuente de verdad)
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
        for (_, scorer) in scorerPorBola {
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
            if let (eIdx, jIdx) = encontrarJugador(scorer8),
               equipos[eIdx].tipo == ganador {
                asegurarTamanosIndividual(enEquipo: eIdx)
                equipos[eIdx].puntajeIndividual[jIdx] += 1
            }
        }
    }

    // Reset
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

    // Helpers
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

// =====================================================
// MARK: - ResultadosSheet (dentro del mismo archivo)
// =====================================================

struct ResultadosSheet: View {

    let textoBannerFinal: String
    let equipos: [Equipo]
    let accion: ScoresView.AccionPostResultados

    let onResetConfirmado: () -> Void
    let onNuevaConfirmado: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {

                Text(textoBannerFinal)
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(equipos) { e in
                        HStack {
                            Text("Equipo \(e.tipo == .par ? "PAR" : "IMPAR")")
                                .font(.headline)
                            Spacer()
                            Text("\(e.puntajeActual)")
                                .font(.headline)
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.10))
                .cornerRadius(12)

                Spacer()

                if accion == .reset {
                    Button {
                        onResetConfirmado()
                    } label: {
                        Text("Nueva partida (mismos jugadores)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(12)
                    }
                } else {
                    Button {
                        onNuevaConfirmado()
                    } label: {
                        Text("Ir al inicio (nueva asignación)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(12)
                    }
                }

                Spacer().frame(height: 10)
            }
            .padding(.horizontal)
            .navigationTitle("Resultados")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled(true)
        .presentationDetents(Set<PresentationDetent>([.medium, .large]))
    }
}

