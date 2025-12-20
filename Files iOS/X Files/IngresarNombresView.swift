import SwiftUI

// -----------------------------------------------
// Normaliza nombres al FINAL (para validar/pasar a Ruleta):
// "  lUiS  pErEz " → "Luis Perez"
// - Quita espacios extra
// - Capitaliza cada palabra
// -----------------------------------------------
func normalizarNombre(_ texto: String) -> String {
    let trimmed = texto.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "" }

    let parts = trimmed
        .split(whereSeparator: { $0.isWhitespace })
        .map(String.init)

    let normalizedWords = parts.map { word -> String in
        let lower = word.lowercased()
        let first = lower.prefix(1).uppercased()
        let rest = lower.dropFirst()
        return first + rest
    }

    return normalizedWords.joined(separator: " ")
}

// -----------------------------------------------
// EN VIVO (mientras escribes):
// ✅ Desde la primera letra: "a" -> "A", "aaaa" -> "Aaaa"
// ✅ Capitaliza cada palabra después de espacio
// ✅ No fuerza el resto a minúsculas
// ✅ Limpia espacios al inicio y colapsa múltiples
// ✅ Respeta el espacio final si estás escribiendo 2 nombres
// -----------------------------------------------
func normalizarNombreEnVivo(_ texto: String) -> String {
    if texto.isEmpty { return "" }

    let endsWithSpace = texto.last?.isWhitespace ?? false

    // 1) Quitar espacios al inicio
    var s = texto
    while let first = s.first, first.isWhitespace { s.removeFirst() }

    // 2) Colapsar espacios múltiples a uno solo (sin romper el trailing space)
    var collapsed = ""
    var lastWasSpace = false
    for ch in s {
        if ch.isWhitespace {
            if !lastWasSpace {
                collapsed.append(" ")
            }
            lastWasSpace = true
        } else {
            collapsed.append(ch)
            lastWasSpace = false
        }
    }

    // Si el usuario acaba en espacio, lo dejamos (1 solo)
    if endsWithSpace, !collapsed.isEmpty, collapsed.last != " " {
        collapsed.append(" ")
    }

    // 3) Capitalizar primera letra de cada palabra (sin tocar el resto)
    var result = ""
    var capNext = true

    for ch in collapsed {
        if ch == " " {
            result.append(ch)
            capNext = true
            continue
        }

        if capNext, ch.isLetter {
            result.append(String(ch).uppercased())
            capNext = false
        } else {
            result.append(ch)
            capNext = false
        }
    }

    return result
}

// Cuenta letras (A–Z) ignorando espacios y símbolos, para regla min 4
func cuentaLetras(_ texto: String) -> Int {
    texto.filter { $0.isLetter }.count
}

// -----------------------------------------------
// Vista principal para ingresar nombres
// -----------------------------------------------
struct IngresarNombresView: View {

    let teamCount: Int
    var maxJugadores: Int { teamCount * 2 }

    @State private var nombres: [String]
    @State private var mostrarAlerta = false
    @State private var mensajeAlerta = ""
    @State private var irARuleta = false

    @FocusState private var foco: Int?

    init(teamCount: Int) {
        self.teamCount = teamCount
        let max = teamCount * 2
        _nombres = State(initialValue: Array(repeating: "", count: max))
    }

    // Nombres normalizados (uno por jugador, mismo tamaño que maxJugadores)
    private var nombresNormalizados: [String] {
        nombres.map { normalizarNombre($0) }
    }

    // Validez: todos llenos + min 4 letras
    private var todosValidos: Bool {
        let lista = nombresNormalizados
        guard lista.count == maxJugadores else { return false }
        return lista.allSatisfy { !$0.isEmpty && cuentaLetras($0) >= 4 }
    }

    // Duplicados (case-insensitive, basado en normalizado)
    private var hayDuplicados: Bool {
        let lista = nombresNormalizados.map { $0.lowercased() }
        return Set(lista).count != lista.count
    }

    var body: some View {
        VStack(spacing: 16) {

            Text("Ingresar jugadores")
                .font(.title.bold())

            Text("Mínimo 4 letras por nombre")
                .font(.caption)
                .foregroundColor(.secondary)

            List {
                ForEach(nombres.indices, id: \.self) { index in
                    TextField(
                        "Jugador \(index + 1)",
                        text: Binding(
                            get: { nombres[index] },
                            set: { nuevo in
                                // ✅ UX #1: capitaliza desde la primera letra
                                nombres[index] = normalizarNombreEnVivo(nuevo)
                            }
                        )
                    )
                    .textInputAutocapitalization(.never) // evitamos que el teclado “pelee”
                    .autocorrectionDisabled()
                    .focused($foco, equals: index)
                    .submitLabel(index == maxJugadores - 1 ? .done : .next)
                    .onSubmit {
                        if index < maxJugadores - 1 { foco = index + 1 }
                        else { foco = nil }
                    }
                }
            }

            Button {
                if !todosValidos {
                    mensajeAlerta = "Completa los \(maxJugadores) nombres (mínimo 4 letras cada uno)."
                    mostrarAlerta = true
                    return
                }
                if hayDuplicados {
                    mensajeAlerta = "Hay nombres duplicados. Corrígelos para continuar."
                    mostrarAlerta = true
                    return
                }

                foco = nil
                irARuleta = true

            } label: {
                Text("Continuar → Ruleta")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background((todosValidos && !hayDuplicados) ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            Spacer(minLength: 6)
        }
        .padding()
        .navigationDestination(isPresented: $irARuleta) {
            RuletaView(jugadores: nombresNormalizados)
        }
        .alert("Revisar nombres", isPresented: $mostrarAlerta) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(mensajeAlerta)
        }
        .onAppear {
            foco = 0
        }
    }
}
