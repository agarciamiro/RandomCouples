import SwiftUI
import UIKit

// ===============================================================
// Store simple para guardar los 2 nombres (opcional, pero útil)
// ===============================================================

private enum BackgammonPlayersStore {
    private static let key = "BG_PLAYERS_V1"

    static func save(_ players: [String]) {
        let data = try? JSONEncoder().encode(players)
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> [String] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let players = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return players
    }
}

// ===============================================================
// Helpers (Backgammon)
// ===============================================================

private func normalizarNombreBG(_ texto: String) -> String {
    let trimmed = texto.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "" }

    let parts = trimmed
        .split(whereSeparator: { $0.isWhitespace })
        .map(String.init)

    return parts.joined(separator: " ").uppercased()
}

private func cuentaLetrasBG(_ texto: String) -> Int {
    texto.filter { $0.isLetter }.count
}

// ===============================================================
// UITextField wrapper: MAYÚSCULAS en vivo (a prueba de iPhone)
// ===============================================================

private struct UppercaseTextFieldBackgammon: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var returnKeyType: UIReturnKeyType = .next
    @Binding var isFirstResponder: Bool
    var onReturn: (() -> Void)? = nil

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.autocorrectionType = .no
        tf.autocapitalizationType = .allCharacters
        tf.returnKeyType = returnKeyType
        tf.delegate = context.coordinator
        tf.borderStyle = .roundedRect
        tf.text = text.uppercased()
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        let desired = text.uppercased()
        if uiView.text != desired { uiView.text = desired }

        if isFirstResponder, uiView.window != nil, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFirstResponder, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }

        uiView.returnKeyType = returnKeyType
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: UppercaseTextFieldBackgammon

        init(parent: UppercaseTextFieldBackgammon) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFirstResponder = true
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn?()
            return false
        }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {

            let current = textField.text ?? ""
            guard let r = Range(range, in: current) else { return true }

            let updated = current.replacingCharacters(in: r, with: string).uppercased()

            textField.text = updated
            parent.text = updated

            let newCursorPos = range.location + (string as NSString).length
            if let pos = textField.position(from: textField.beginningOfDocument, offset: newCursorPos) {
                textField.selectedTextRange = textField.textRange(from: pos, to: pos)
            }

            return false
        }
    }
}

// ===============================================================
// Vista principal
// ===============================================================

struct BackgammonIngresarJugadoresView: View {

    @State private var jugador1: String = ""
    @State private var jugador2: String = ""

    @State private var mostrarAlerta: Bool = false
    @State private var mensajeAlerta: String = ""

    @State private var irSiguiente: Bool = false
    @State private var focoIndex: Int? = 0

    private var jugadoresNormalizados: [String] {
        [normalizarNombreBG(jugador1), normalizarNombreBG(jugador2)]
    }

    private var todosValidos: Bool {
        let j = jugadoresNormalizados
        return j.allSatisfy { !$0.isEmpty && cuentaLetrasBG($0) >= 4 }
    }

    private var hayDuplicados: Bool {
        let j = jugadoresNormalizados.map { $0.lowercased() }
        return Set(j).count != j.count
    }

    var body: some View {

        VStack(spacing: 16) {

            Text("Jugadores")
                .font(.title.bold())

            VStack(spacing: 12) {

                UppercaseTextFieldBackgammon(
                    placeholder: "Jugador 1",
                    text: $jugador1,
                    returnKeyType: .next,
                    isFirstResponder: Binding(
                        get: { focoIndex == 0 },
                        set: { if $0 { focoIndex = 0 } }
                    ),
                    onReturn: { focoIndex = 1 }
                )

                UppercaseTextFieldBackgammon(
                    placeholder: "Jugador 2",
                    text: $jugador2,
                    returnKeyType: .done,
                    isFirstResponder: Binding(
                        get: { focoIndex == 1 },
                        set: { if $0 { focoIndex = 1 } }
                    ),
                    onReturn: { focoIndex = nil }
                )
            }
            .padding(.horizontal)

            Button {
                if !todosValidos {
                    mensajeAlerta = "Ingresa 2 nombres (mínimo 4 letras cada uno)."
                    mostrarAlerta = true
                    return
                }

                if hayDuplicados {
                    mensajeAlerta = "Los nombres no pueden ser iguales."
                    mostrarAlerta = true
                    return
                }

                BackgammonPlayersStore.save(jugadoresNormalizados)

                focoIndex = nil
                irSiguiente = true

            } label: {
                Text("Continuar")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background((todosValidos && !hayDuplicados) ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(28)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 20)

        // ✅ FIX: onContinue recibe 1 parámetro (lo ignoramos con "_")
        .navigationDestination(isPresented: $irSiguiente) {
            BackgammonColorRouletteView(
                player1Name: jugadoresNormalizados[0],
                player2Name: jugadoresNormalizados[1],
                onAssigned: { _ in
                    // por ahora no hacemos nada aquí (solo compatibilidad)
                }
            )
            // <-- AQUÍ DEBERÍA CERRARSE navigationDestination
        }
        .alert("Revisar", isPresented: $mostrarAlerta) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mensajeAlerta)
        }

        .onAppear {
            focoIndex = 0
            let prev = BackgammonPlayersStore.load()
            if prev.count == 2 {
                jugador1 = prev[0]
                jugador2 = prev[1]
            }
        }
    }
}
