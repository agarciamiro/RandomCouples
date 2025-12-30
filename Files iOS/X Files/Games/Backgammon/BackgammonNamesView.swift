import SwiftUI
import UIKit

struct BackgammonNamesView: View {

    // Compatibilidad (por si te llaman con config desde otro flujo)
    let config: BackgammonConfig?

    init(config: BackgammonConfig? = nil) {
        self.config = config
    }

    // ---------------------------------------------------------
    // State
    // ---------------------------------------------------------
    @State private var p1: String = ""
    @State private var p2: String = ""

    @State private var lockedP1: String = ""
    @State private var lockedP2: String = ""

    @State private var mostrarAlerta: Bool = false
    @State private var mensajeAlerta: String = ""

    // ✅ Navegación (trigger)
    @State private var goColors: Bool = false

    @FocusState private var focusedField: Field?
    private enum Field { case p1, p2 }

    // ---------------------------------------------------------
    // Validation
    // ---------------------------------------------------------
    private var p1Trim: String { trimmed(p1) }
    private var p2Trim: String { trimmed(p2) }

    private var isValid: Bool {
        let a = p1Trim.lowercased()
        let b = p2Trim.lowercased()
        return countLetters(p1Trim) >= 4 && countLetters(p2Trim) >= 4 && a != b
    }

    // ---------------------------------------------------------
    // UI
    // ---------------------------------------------------------
    var body: some View {
        VStack(spacing: 18) {

            VStack(spacing: 6) {
                Text("Backgammon")
                    .font(.title.bold())
                Text("Ingresar jugadores")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 10)

            VStack(spacing: 12) {

                TextField("Jugador 1", text: $p1)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .keyboardType(.default)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .p1)
                    .onSubmit { focusedField = .p2 }
                    .onChange(of: p1) { _, newValue in
                        let cleaned = normalizeLive(newValue)
                        if cleaned != newValue { p1 = cleaned }
                    }
                    .textFieldStyle(.roundedBorder)

                TextField("Jugador 2", text: $p2)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .keyboardType(.default)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .p2)
                    .onSubmit { focusedField = nil }
                    .onChange(of: p2) { _, newValue in
                        let cleaned = normalizeLive(newValue)
                        if cleaned != newValue { p2 = cleaned }
                    }
                    .textFieldStyle(.roundedBorder)

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

            // ✅ Trigger invisible para navegar (SIN crear NavigationStack aquí)
            NavigationLink(
                destination: BackgammonColorRouletteView(
                    player1Name: lockedP1,
                    player2Name: lockedP2
                ) { _ in
                    // Retorna BackgammonColorAssignment cuando termina la ruleta.
                    // Por ahora no hacemos nada aquí.
                },
                isActive: $goColors
            ) { EmptyView() }
            .hidden()

            Spacer()
        }
        .padding(.bottom, 14)
        .alert("Atención", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mensajeAlerta)
        }
        .onAppear {
            focusedField = .p1
        }
    }

    // ---------------------------------------------------------
    // Actions
    // ---------------------------------------------------------
    private func attemptContinue() {
        let a = p1Trim
        let b = p2Trim

        guard countLetters(a) >= 4, countLetters(b) >= 4 else {
            mensajeAlerta = "Cada nombre debe tener mínimo 4 letras."
            mostrarAlerta = true
            return
        }
        guard a.lowercased() != b.lowercased() else {
            mensajeAlerta = "Los nombres deben ser diferentes."
            mostrarAlerta = true
            return
        }

        lockedP1 = a
        lockedP2 = b

        goColors = true
    }

    // ---------------------------------------------------------
    // Helpers
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
