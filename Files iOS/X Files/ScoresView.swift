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
