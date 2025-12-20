import SwiftUI

struct ScoresView: View {

    @Binding var equipos: [Equipo]

    // Motor de turnos
    @StateObject var turnos: TurnosEngine

    // Reglas PAR/IMPAR
    let bolasPar = [2, 4, 6, 10, 12, 14, 15]
    let bolasImpar = [1, 3, 5, 7, 9, 11, 13]

    // Registro real
    @State var metidasPar: Set<Int> = []
    @State var metidasImpar: Set<Int> = []

    // Scorer por bola (solo si fue válida para el tirador)
    @State var scorerPorBola: [Int: String] = [:]

    // Picker bolas (para el "+" del jugador en turno)
    @State var mostrarPickerBola = false
    @State var pickerTipoSeleccionado: TipoEquipo = .par

    // Bola 8
    @State var mostrarSheetBola8 = false
    @State var bola8Resuelta = false
    @State var ganadorPor8: TipoEquipo? = nil
    @State var bola8ScorerNombre: String? = nil
    @State var bola8FueAdelantada = false
    @State var bola8FueIncorrecta = false
    @State var troneraCantada: Int = 1

    // Resultados
    enum AccionPostResultados { case reset, nueva }
    @State var mostrarResultados = false
    @State var accionPendiente: AccionPostResultados = .reset

    // Volver al inicio (sin depender de HomeView)
    @State var mostrarInicio = false
    @State var irAlInicioPendiente = false

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
