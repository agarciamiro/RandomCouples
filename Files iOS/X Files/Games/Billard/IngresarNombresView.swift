import SwiftUI
import UIKit

struct IngresarNombresView: View {

    // ---------------------------------------------------------
    // Inputs
    // ---------------------------------------------------------
    let teamCount: Int
    var maxJugadores: Int { teamCount * 2 }

    // ---------------------------------------------------------
    // State
    // ---------------------------------------------------------
    @State private var nombres: [String]

    @State private var mostrarAlerta: Bool = false
    @State private var mensajeAlerta: String = ""

    @State private var irARuleta: Bool = false

    @FocusState private var focusedIndex: Int?

    // ---------------------------------------------------------
    // Init
    // ---------------------------------------------------------
    init(teamCount: Int) {
        self.teamCount = teamCount
        let max = teamCount * 2
        _nombres = State(initialValue: Array(repeating: "", count: max))
    }

    // ---------------------------------------------------------
    // Validation (MISMO CRITERIO QUE BACKGAMMON)
    // ---------------------------------------------------------
    private var nombresTrimmed: [String] {
        nombres.map { trimmed($0) }
    }

    private var isValid: Bool {
        let lista = nombresTrimmed.map { $0.lowercased() }
        guard lista.count == maxJugadores else { return false }
        guard lista.allSatisfy({ countLetters($0) >= 4 }) else { return false }
        return Set(lista).count == lista.count
    }

    // ---------------------------------------------------------
    // UI
    // ---------------------------------------------------------
    var body: some View {
        VStack(spacing: 18) {

            VStack(spacing: 6) {
                Text("Billar")
                    .font(.title.bold())
                Text("Ingresar jugadores")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)

            VStack(spacing: 12) {

                ForEach(nombres.indices, id: \.self) { index in
                    TextField(
                        "Jugador \(index + 1)",
                        text: $nombres[index]
                    )
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .keyboardType(.default)
                    .submitLabel(index == maxJugadores - 1 ? .done : .next)
                    .focused($focusedIndex, equals: index)
                    .onSubmit {
                        if index < maxJugadores - 1 {
                            focusedIndex = index + 1
                        } else {
                            focusedIndex = nil
                        }
                    }
                    .onChange(of: nombres[index]) { _, newValue in
                        let cleaned = normalizeLive(newValue)
                        if cleaned != newValue {
                            nombres[index] = cleaned
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("✅ Mínimo 4 letras c/u")
                    Spacer()
                    Text("🚫 Nombres iguales")
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 2)
            }
            .padding(.horizontal, 18)

            Button {
                attemptContinue()
            } label: {
                Text("Continuar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 18)
            .disabled(!isValid)

            Spacer()
        }
        .padding(.bottom, 14)
        .alert("Atención", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mensajeAlerta)
        }
        .navigationDestination(isPresented: $irARuleta) {
            RuletaView(jugadores: nombresTrimmed)
        }
        .onAppear {
            focusedIndex = 0
        }
    }

    // ---------------------------------------------------------
    // Actions
    // ---------------------------------------------------------
    private func attemptContinue() {

        let lista = nombresTrimmed

        guard lista.allSatisfy({ countLetters($0) >= 4 }) else {
            mensajeAlerta = "Cada nombre debe tener mínimo 4 letras."
            mostrarAlerta = true
            return
        }

        guard Set(lista.map { $0.lowercased() }).count == lista.count else {
            mensajeAlerta = "Los nombres deben ser diferentes."
            mostrarAlerta = true
            return
        }

        focusedIndex = nil
        irARuleta = true
    }

    // ---------------------------------------------------------
    // Helpers (MISMO SISTEMA QUE BACKGAMMON)
    // ---------------------------------------------------------
    private func normalizeLive(_ input: String) -> String {
        let collapsed = collapseSpaces(input)
        let trimmedValue = collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.uppercased(with: Locale(identifier: "es_PE"))
    }

    private func trimmed(_ s: String) -> String {
        collapseSpaces(s)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased(with: Locale(identifier: "es_PE"))
    }

    private func collapseSpaces(_ s: String) -> String {
        s.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
            .joined(separator: " ")
    }

    private func countLetters(_ s: String) -> Int {
        s.filter { $0.isLetter }.count
    }
}
