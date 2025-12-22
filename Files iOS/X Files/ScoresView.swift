import SwiftUI
import UIKit

struct ScoresView: View {

    @Binding var equipos: [Equipo]
    @StateObject var turnos: TurnosEngine
    let ordenJugadores: [String]

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
    @State private var pickerSheetID = UUID()

    // Bola 8
    @State var mostrarSheetBola8 = false
    @State var bola8Resuelta = false
    @State var ganadorPor8: TipoEquipo? = nil
    @State var bola8ScorerNombre: String? = nil
    @State var bola8FueAdelantada = false
    @State var bola8FueIncorrecta = false
    @State var troneraCantada: Int = 1

    // ✅ Pantalla final (2 botones)
    @State private var mostrarPantallaFinal = false

    // Volver al inicio
    @State private var mostrarInicio = false

    // ✅ Alternancia de “Nueva Partida”
    @State private var empiezaPartidaActual: TipoEquipo? = nil

    // Troneras (siglas)
    let troneraSiglas: [Int: String] = [
        1: "EDFr",
        2: "CFr",
        3: "EIFr",
        4: "EiFo",
        5: "CFo",
        6: "EDFo"
    ]

    // ✅ Estado único “partida finalizada”
    var juegoFinalizado: Bool { bola8Resuelta && (ganadorPor8 != nil) }

    // MARK: - INITS
    init(equipos: Binding<[Equipo]>) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: TurnosEngine(equipos: equipos.wrappedValue))
        self.ordenJugadores = []
    }

    init(equipos: Binding<[Equipo]>, turnos: TurnosEngine, ordenJugadores: [String] = []) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: turnos)
        self.ordenJugadores = ordenJugadores
    }

    init(equipos: Binding<[Equipo]>, _ turnos: TurnosEngine, _ ordenJugadores: [String]) {
        self._equipos = equipos
        self._turnos = StateObject(wrappedValue: turnos)
        self.ordenJugadores = ordenJugadores
    }

    // MARK: - BODY
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {

                bannerEstadoPartida

                // ✅ Solo si la partida sigue viva
                if !juegoFinalizado {
                    cardTurnosCompacto

                    if !ordenJugadores.isEmpty {
                        cardOrdenJugadoresCompacto
                    }
                }

                // ✅ Inventario siempre visible
                cardRegistroBolas

                // ✅ Equipos: si finalizado => ganador primero y sin "+"
                ForEach(equiposOrdenadosParaVista.indices, id: \.self) { idx in
                    let originalIndex = equiposOrdenadosParaVista[idx].0
                    let bindingEq = $equipos[originalIndex]

                    if juegoFinalizado {
                        tarjetaEquipoFinal(bindingEq)
                    } else {
                        tarjetaEquipo(bindingEq)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Puntajes")
        .navigationBarTitleDisplayMode(.inline)

        // ✅ Bloquea back (evita volver a ruleta / reset)
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()

        // ✅ Sin toolbar “Nueva/Finalizar”
        .toolbar { }

        // Sheets
        .onChange(of: mostrarPickerBola) { _, showing in
            if showing { pickerTipoSeleccionado = turnos.turnoActual.tipo }
        }
        .sheet(isPresented: $mostrarPickerBola) {
            pickerBolaSheet.id(pickerSheetID)
        }
        .sheet(isPresented: $mostrarSheetBola8) { bola8Sheet }

        // ✅ Pantalla final con SOLO 2 botones
        .fullScreenCover(isPresented: $mostrarPantallaFinal) {
            PantallaFinalPartida(
                textoBannerFinal: textoBannerFinal,
                equiposOrdenados: equiposOrdenadosParaSheet,
                onNuevaPartida: {
                    resetTodo()
                    iniciarNuevaPartidaAlternandoEquipo()
                    mostrarPantallaFinal = false
                },
                onFinalizar: {
                    resetTodo()
                    mostrarPantallaFinal = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        mostrarInicio = true
                    }
                }
            )
            .interactiveDismissDisabled(true)
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

        .onAppear {
            resetPuntajesSolo()
            if empiezaPartidaActual == nil {
                empiezaPartidaActual = turnos.turnoActual.tipo
            }
        }
    }
}

// MARK: - Banner / Orden
extension ScoresView {

    // ✅ Orden equipos: ganador primero al finalizar
    var equiposOrdenadosParaVista: [(Int, Equipo)] {
        let arr: [(Int, Equipo)] = equipos.enumerated().map { ($0.offset, $0.element) }
        guard juegoFinalizado, let g = ganadorPor8 else { return arr }
        return arr.sorted { a, b in
            let aWin = (a.1.tipo == g)
            let bWin = (b.1.tipo == g)
            if aWin != bWin { return aWin && !bWin }
            return a.1.numero < b.1.numero
        }
    }

    var equiposOrdenadosParaSheet: [Equipo] {
        equiposOrdenadosParaVista.map { $0.1 }
    }

    // ✅ Banner centrado (mismo tamaño)
    var bannerEstadoPartida: some View {
        Text(juegoFinalizado ? textoBannerFinal : textoBannerVivo)
            .font(.footnote.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color.green.opacity(0.78))
            .cornerRadius(14)
    }

    var textoBannerVivo: String {
        let p = metidasPar.count
        let i = metidasImpar.count

        if p == 7 && i == 7 { return "AMBOS A 7 — SE DEFINE CON LA 8" }
        if p == 7 { return "PAR YA PUEDE CANTAR LA 8 — PAR 7 vs IMPAR \(i)" }
        if i == 7 { return "IMPAR YA PUEDE CANTAR LA 8 — IMPAR 7 vs PAR \(p)" }

        if p == i { return "VAN EMPATANDO — \(p) BOLAS" }
        if p > i { return "VA GANANDO PAR — \(p) BOLAS" }
        return "VA GANANDO IMPAR — \(i) BOLAS"
    }

    // ✅ Final: ganador arriba, perdedor abajo
    var textoBannerFinal: String {
        guard let ganador = ganadorPor8 else { return "—" }
        let perdedor: TipoEquipo = (ganador == .par) ? .impar : .par

        let g = ganador.titulo.uppercased()
        let p = perdedor.titulo.uppercased()

        let tg = totalFinal(ganador)
        let tp = totalFinal(perdedor)

        let motivo: String = {
            if bola8FueAdelantada { return " — 8 ADELANTADA" }
            if bola8FueIncorrecta { return " — TRONERA INCORRECTA" }
            return ""
        }()

        return "🏆 GANÓ EQUIPO \(g) (\(tg))\(motivo)\nPERDIÓ EQUIPO \(p) (\(tp))"
    }

    // Orden jugadores: muestra 4, y desde ahí scroll interno
    var cardOrdenJugadoresCompacto: some View {

        let visibles = Array(ordenJugadores.prefix(4))
        let resto = Array(ordenJugadores.dropFirst(4))
        let cols = [GridItem(.flexible()), GridItem(.flexible())]

        func chip(_ idx: Int, _ nombre: String) -> some View {
            HStack(spacing: 6) {
                Text("\(idx)")
                    .font(.caption2.bold())
                    .frame(width: 18, height: 18)
                    .background(Color.gray.opacity(0.22))
                    .clipShape(Circle())

                Text(nombre)
                    .font(.caption2.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 8)
            .background(Color.gray.opacity(0.10))
            .cornerRadius(10)
        }

        return VStack(alignment: .leading, spacing: 6) {
            Text("Orden de jugadores")
                .font(.footnote.bold())

            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(visibles.indices, id: \.self) { i in
                    chip(i + 1, visibles[i])
                }
            }

            if !resto.isEmpty {
                Divider().opacity(0.25)
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(columns: cols, spacing: 6) {
                        ForEach(resto.indices, id: \.self) { i in
                            chip(i + 5, resto[i])
                        }
                    }.padding(.top, 2)
                }
                .frame(maxHeight: 84)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Turnos
extension ScoresView {

    var cardTurnosCompacto: some View {
        VStack(spacing: 6) {

            HStack(spacing: 8) {
                Text("Empieza: \(turnos.empiezaPartida.titulo)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Toggle("Auto", isOn: $turnos.modoAutoAvance)
                    .labelsHidden()
                    .scaleEffect(0.9)

                Button { turnos.siguienteTurno() } label: {
                    Text("Siguiente")
                        .font(.caption.bold())
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(Color.black.opacity(0.85))
                    .frame(width: 16, height: 16)
                    .overlay(Text("8").font(.caption2.bold()).foregroundColor(.white))
                    .opacity(turnos.bolaEnManoParaSiguiente ? 1 : 0.30)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Turno")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(turnos.turnoActual.tipo.titulo) — \(turnos.turnoActual.jugadorNombre)")
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text("Equipo #\(turnos.turnoActual.equipoNumero)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if turnos.bolaEnManoParaSiguiente {
                    Text("Bola en mano")
                        .font(.caption2.bold())
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(Color.orange.opacity(0.22))
                        .cornerRadius(10)
                }
            }

            Button {
                turnos.registrarTiro(anotoBolaValida: false, fueFalta: true)
            } label: {
                Text("Falta: Blanca / Rival")
                    .font(.caption.bold())
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.16))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Registro de bolas
extension ScoresView {

    var cardRegistroBolas: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack {
                Text("Registro de Bolas")
                    .font(.footnote.bold())

                Spacer()

                if !juegoFinalizado {
                    Button("Reset") { resetBolas() }
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PAR")
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                    gridBolas(bolasPar, tipo: .par)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("IMPAR")
                        .font(.caption2.bold())
                        .foregroundColor(.red)
                    gridBolas(bolasImpar, tipo: .impar)
                }
            }

            if !juegoFinalizado {
                Divider().padding(.top, 2)

                // ✅ Siempre visible
                Button { registrarBola8Adelantada() } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.black.opacity(0.85))
                            .frame(width: 20, height: 20)
                            .overlay(Text("8").font(.caption2.bold()).foregroundColor(.white))

                        Text("Bola #8 ingresada antes del final del juego")
                            .font(.caption.bold())
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow.opacity(0.85))
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }

                if (metidasPar.count == 7 || metidasImpar.count == 7) {
                    let t =
                    (metidasPar.count == 7 && metidasImpar.count == 7)
                    ? "🎱 Ambos ya pueden cantar la 8"
                    : (metidasPar.count == 7 ? "🎱 PAR ya puede cantar la 8" : "🎱 IMPAR ya puede cantar la 8")

                    Text(t)
                        .font(.caption.bold())
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.16))
                        .cornerRadius(12)

                    let colorFondo: Color = {
                        if metidasPar.count == 7 && metidasImpar.count < 7 { return .blue }
                        if metidasImpar.count == 7 && metidasPar.count < 7 { return .red }
                        return .green
                    }()

                    Button { abrirRegistroBola8() } label: {
                        Text("🎱 Registrar bola 8 (turno: \(turnos.turnoActual.tipo.titulo))")
                            .font(.caption.bold())
                            .padding(.vertical, 9)
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
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    func gridBolas(_ bolas: [Int], tipo: TipoEquipo) -> some View {
        let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: cols, spacing: 6) {
            ForEach(bolas, id: \.self) { n in
                bolaChip(numero: n, tipo: tipo)
            }
        }
    }

    func bolaChip(numero: Int, tipo: TipoEquipo) -> some View {
        let marcada = (tipo == .par) ? metidasPar.contains(numero) : metidasImpar.contains(numero)
        let color: Color = (tipo == .par) ? .blue : .red

        return Button {
            guard !juegoFinalizado else { return }
            if marcada { desmarcarBola(numero: numero) }
        } label: {
            Circle()
                .fill(marcada ? color.opacity(0.92) : Color.gray.opacity(0.12))
                .frame(width: 30, height: 30)
                .overlay(
                    Text("\(numero)")
                        .font(.caption2.bold())
                        .foregroundColor(marcada ? .white : .primary)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Equipos
extension ScoresView {

    func esJugadorDeTurno(_ nombre: String) -> Bool {
        nombre == turnos.turnoActual.jugadorNombre
    }

    func tarjetaEquipo(_ equipo: Binding<Equipo>) -> some View {
        let color: Color = (equipo.wrappedValue.tipo == .par) ? .blue : .red

        return VStack(alignment: .leading, spacing: 6) {

            HStack {
                Text("Equipo #\(equipo.wrappedValue.numero)  \(equipo.wrappedValue.tipo.titulo)")
                    .font(.caption.bold())
                    .foregroundColor(color)

                Spacer()

                Text("Total: \(equipo.wrappedValue.puntajeActual)")
                    .font(.caption.bold())
            }

            Divider()

            ForEach(equipo.wrappedValue.jugadores.indices, id: \.self) { idx in
                let nombre = equipo.wrappedValue.jugadores[idx].nombre
                let indiv = (idx < equipo.wrappedValue.puntajeIndividual.count) ? equipo.wrappedValue.puntajeIndividual[idx] : 0
                let enTurno = esJugadorDeTurno(nombre)

                HStack(spacing: 8) {
                    Text(nombre)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)

                    Spacer()

                    Text("\(indiv)")
                        .font(.caption.bold())
                        .frame(width: 22, alignment: .trailing)

                    if enTurno {
                        // ✅ FIX: sin DispatchQueue.main.async (evita abrir con tipo viejo)
                        Button {
                            pickerTipoSeleccionado = turnos.turnoActual.tipo
                            pickerSheetID = UUID()
                            mostrarPickerBola = true
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
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    func tarjetaEquipoFinal(_ equipo: Binding<Equipo>) -> some View {
        let color: Color = (equipo.wrappedValue.tipo == .par) ? .blue : .red

        return VStack(alignment: .leading, spacing: 6) {

            HStack {
                Text("Equipo #\(equipo.wrappedValue.numero)  \(equipo.wrappedValue.tipo.titulo)")
                    .font(.caption.bold())
                    .foregroundColor(color)

                Spacer()

                Text("Total: \(equipo.wrappedValue.puntajeActual)")
                    .font(.caption.bold())
            }

            Divider()

            ForEach(equipo.wrappedValue.jugadores.indices, id: \.self) { idx in
                let nombre = equipo.wrappedValue.jugadores[idx].nombre
                let indiv = (idx < equipo.wrappedValue.puntajeIndividual.count) ? equipo.wrappedValue.puntajeIndividual[idx] : 0

                HStack(spacing: 8) {
                    Text(nombre)
                        .font(.caption2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)

                    Spacer()

                    Text("\(indiv)")
                        .font(.caption.bold())
                        .frame(width: 22, alignment: .trailing)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Picker / Registrar / Totales / Reset
extension ScoresView {

    var pickerBolaSheet: some View {
        NavigationStack {
            VStack(spacing: 10) {

                Text("Anotar bola metida")
                    .font(.footnote.bold())
                    .padding(.top, 6)

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
                        spacing: 10
                    ) {
                        ForEach(disponibles, id: \.self) { n in
                            Button {
                                registrarBola(numero: n)
                                mostrarPickerBola = false
                            } label: {
                                Circle()
                                    .fill((pickerTipoSeleccionado == .par ? Color.blue : Color.red).opacity(0.92))
                                    .frame(width: 44, height: 44)
                                    .overlay(Text("\(n)").font(.headline.bold()).foregroundColor(.white))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 6)
                }

                Button("Cerrar") { mostrarPickerBola = false }
                    .font(.footnote.bold())
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.18))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .presentationDetents(Set<PresentationDetent>([.medium, .large]))
        .onAppear { pickerTipoSeleccionado = turnos.turnoActual.tipo }
        .onChange(of: turnos.turnoActual) { _, _ in
            pickerTipoSeleccionado = turnos.turnoActual.tipo
        }
    }

    func registrarBola(numero: Int) {
        guard !juegoFinalizado else { return }

        let tipoBola: TipoEquipo
        if bolasPar.contains(numero) {
            tipoBola = .par
            if metidasPar.contains(numero) { return }
        } else if bolasImpar.contains(numero) {
            tipoBola = .impar
            if metidasImpar.contains(numero) { return }
        } else { return }

        let tipoTurno = turnos.turnoActual.tipo
        let anotoValida = (tipoBola == tipoTurno)
        let fueFalta = !anotoValida

        if tipoBola == .par { metidasPar.insert(numero) } else { metidasImpar.insert(numero) }

        if anotoValida {
            scorerPorBola[numero] = turnos.turnoActual.jugadorNombre
        }

        sincronizarTotales()

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
        if juegoFinalizado, let ganador = ganadorPor8 {
            if ganador == tipo { return 8 }
            return totalBolas(tipo)
        }
        return totalBolas(tipo)
    }

    func sincronizarTotales() {

        for i in equipos.indices {
            equipos[i].puntajeActual = 0
            if equipos[i].puntajeIndividual.count != equipos[i].jugadores.count {
                equipos[i].puntajeIndividual = Array(repeating: 0, count: equipos[i].jugadores.count)
            } else {
                for j in equipos[i].puntajeIndividual.indices { equipos[i].puntajeIndividual[j] = 0 }
            }
        }

        for i in equipos.indices {
            let tipo = equipos[i].tipo
            equipos[i].puntajeActual = (juegoFinalizado ? totalFinal(tipo) : totalBolas(tipo))
        }

        for (_, scorer) in scorerPorBola {
            if let (eIdx, jIdx) = encontrarJugador(scorer) {
                asegurarTamanosIndividual(enEquipo: eIdx)
                equipos[eIdx].puntajeIndividual[jIdx] += 1
            }
        }

        if juegoFinalizado,
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

    func resetTodo() { resetBolas() }

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

// MARK: - Alternar inicio al elegir NUEVA PARTIDA
extension ScoresView {

    func primerJugadorDelTipo(_ tipo: TipoEquipo) -> String? {
        equipos.first(where: { $0.tipo == tipo })?.jugadores.first?.nombre
    }

    func iniciarNuevaPartidaAlternandoEquipo() {
        let actual = empiezaPartidaActual ?? turnos.turnoActual.tipo
        let alterno: TipoEquipo = (actual == .par) ? .impar : .par
        empiezaPartidaActual = alterno

        let primer = primerJugadorDelTipo(alterno)

        for _ in 0..<50 {
            let okTipo = (turnos.turnoActual.tipo == alterno)
            let okNombre = (primer == nil) || (turnos.turnoActual.jugadorNombre == primer!)
            if okTipo && okNombre { break }
            turnos.siguienteTurno()
        }
    }
}

// MARK: - Bola 8
extension ScoresView {

    func presentarPantallaFinalConDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            self.mostrarPantallaFinal = true
        }
    }

    func registrarBola8Adelantada() {
        guard !juegoFinalizado else { return }

        let tipoTirador = turnos.turnoActual.tipo

        bola8Resuelta = true
        bola8FueAdelantada = true
        bola8FueIncorrecta = false

        ganadorPor8 = (tipoTirador == .par) ? .impar : .par
        bola8ScorerNombre = nil

        sincronizarTotales()
        presentarPantallaFinalConDelay()
    }

    func abrirRegistroBola8() {
        troneraCantada = 1
        mostrarSheetBola8 = true
    }

    var bola8Sheet: some View {
        NavigationStack {
            VStack(spacing: 12) {

                HStack {
                    Text("🎱 Registrar bola 8")
                        .font(.footnote.bold())
                    Spacer()
                }

                Text("Turno actual: \(turnos.turnoActual.tipo.titulo) — \(turnos.turnoActual.jugadorNombre)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tronera cantada")
                        .font(.caption.bold())

                    Picker("Tronera", selection: $troneraCantada) {
                        ForEach(1...6, id: \.self) { n in
                            Text(troneraSiglas[n] ?? "—").tag(n)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(10)
                .background(Color.gray.opacity(0.10))
                .cornerRadius(14)

                Button {
                    resolverBola8(fueEnTroneraCantada: true)
                    mostrarSheetBola8 = false
                } label: {
                    Text("✅ Entró en la tronera cantada")
                        .font(.caption.bold())
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
                        .font(.caption.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.90))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }

                Button { mostrarSheetBola8 = false } label: {
                    Text("Cancelar")
                        .font(.caption.bold())
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.16))
                        .foregroundColor(.primary)
                        .cornerRadius(14)
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        .presentationDetents(Set<PresentationDetent>([.medium, .large]))
    }

    func resolverBola8(fueEnTroneraCantada: Bool) {
        guard !juegoFinalizado else { return }

        let tipoTirador = turnos.turnoActual.tipo
        let tiradorTiene7 = (tipoTirador == .par) ? (metidasPar.count == 7) : (metidasImpar.count == 7)

        bola8Resuelta = true
        bola8FueAdelantada = false
        bola8FueIncorrecta = false

        if !tiradorTiene7 {
            ganadorPor8 = (tipoTirador == .par) ? .impar : .par
            bola8FueAdelantada = true
            bola8ScorerNombre = nil
        } else if !fueEnTroneraCantada {
            ganadorPor8 = (tipoTirador == .par) ? .impar : .par
            bola8FueIncorrecta = true
            bola8ScorerNombre = nil
        } else {
            ganadorPor8 = tipoTirador
            bola8ScorerNombre = turnos.turnoActual.jugadorNombre
        }

        sincronizarTotales()
        presentarPantallaFinalConDelay()
    }
}

// MARK: - Pantalla Final (2 botones)
struct PantallaFinalPartida: View {

    let textoBannerFinal: String
    let equiposOrdenados: [Equipo]

    let onNuevaPartida: () -> Void
    let onFinalizar: () -> Void

    // ✅ FIX: Fondo opaco para evitar transparencia/superposición visual
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            NavigationStack {
                VStack(spacing: 12) {

                    Text("FIN DE PARTIDA")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)

                    Text(textoBannerFinal)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .background(Color.green.opacity(0.78))
                        .cornerRadius(14)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(equiposOrdenados) { eq in
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
                    }

                    Button(action: onNuevaPartida) {
                        Text("NUEVA PARTIDA")
                            .font(.subheadline.bold())
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    Button(action: onFinalizar) {
                        Text("FINALIZAR (IR AL INICIO)")
                            .font(.subheadline.bold())
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Disable swipe back helper
private struct NavControllerAccessor: UIViewControllerRepresentable {
    var onResolve: (UINavigationController?) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async { onResolve(vc.navigationController) }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async { onResolve(uiViewController.navigationController) }
    }
}

private extension View {
    func disableSwipeBack() -> some View {
        self.background(
            NavControllerAccessor { nav in
                nav?.interactivePopGestureRecognizer?.isEnabled = false
            }
        )
    }
}
