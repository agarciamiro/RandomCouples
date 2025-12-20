import SwiftUI

// ===============================================================
//  Helpers de texto
// ===============================================================

/// Normaliza nombres: "  lUiS  pErEz " → "Luis Perez"
/// - Quita espacios extra
/// - Capitaliza cada palabra
/// - Se usa para: validar (min 4 letras / duplicados) y para pasar a Ruleta
func normalizarNombre(_ texto: String) -> String {

    let trimmed = texto.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "" }

    // Colapsa espacios múltiples (por ejemplo: "Luis   Perez" -> ["Luis","Perez"])
    let parts = trimmed
        .split(whereSeparator: { $0.isWhitespace })
        .map(String.init)

    // Capitaliza cada palabra (primera letra mayúscula, resto minúscula)
    let normalizedWords = parts.map { word -> String in
        let lower = word.lowercased()
        let first = lower.prefix(1).uppercased()
        let rest = lower.dropFirst()
        return first + rest
    }

    return normalizedWords.joined(separator: " ")
}

/// Cuenta letras (A–Z / unicode letters) ignorando espacios y símbolos
/// - Regla: mínimo 4 letras por nombre (ej: "Ana" falla, "Juan" pasa)
func cuentaLetras(_ texto: String) -> Int {
    texto.filter { $0.isLetter }.count
}

/// Capitalización “en vivo” (suave) para el TextField:
/// - Solo asegura mayúscula al inicio de cada palabra mientras tipeas.
/// - NO recorta espacios, NO colapsa espacios múltiples, NO fuerza minúsculas.
/// - Objetivo UX: "a" -> "A" al instante; "aaaa" -> "Aaaa"
func capitalizarSuaveEnVivo(_ texto: String) -> String {

    guard !texto.isEmpty else { return "" }

    var resultado = ""
    var debeMayuscula = true

    for ch in texto {

        if ch.isWhitespace {
            // Mantener espacios tal cual (no normalizar mientras se escribe)
            resultado.append(ch)
            debeMayuscula = true
            continue
        }

        if debeMayuscula, ch.isLetter {
            // Solo la primera letra de cada palabra se vuelve mayúscula
            resultado.append(String(ch).uppercased())
            debeMayuscula = false
        } else {
            // El resto queda como lo escribió el usuario
            resultado.append(ch)
            debeMayuscula = false
        }
    }

    return resultado
}


// ===============================================================
//  Vista principal: IngresarNombresView
// ===============================================================

struct IngresarNombresView: View {

    // -----------------------------------------------------------
    // Inputs
    // -----------------------------------------------------------

    let teamCount: Int
    var maxJugadores: Int { teamCount * 2 }

    // -----------------------------------------------------------
    // State
    // -----------------------------------------------------------

    @State private var nombres: [String]

    @State private var mostrarAlerta: Bool = false
    @State private var mensajeAlerta: String = ""

    @State private var irARuleta: Bool = false

    // Manejo de foco para "Next/Done" en teclado
    @FocusState private var foco: Int?

    // -----------------------------------------------------------
    // Init
    // -----------------------------------------------------------

    init(teamCount: Int) {
        self.teamCount = teamCount
        let max = teamCount * 2
        _nombres = State(initialValue: Array(repeating: "", count: max))
    }

    // -----------------------------------------------------------
    // Computed: nombres normalizados (mismo tamaño que maxJugadores)
    // -----------------------------------------------------------

    /// Importante:
    /// - Aquí sí normalizamos (trim + colapsa espacios + capitaliza palabras).
    /// - Esta lista es la que se usa para:
    ///   1) Validación de 4 letras
    ///   2) Validación de duplicados
    ///   3) Enviar a Ruleta
    private var nombresNormalizados: [String] {
        nombres.map { normalizarNombre($0) }
    }

    // -----------------------------------------------------------
    // Computed: reglas de validación
    // -----------------------------------------------------------

    /// Validez: todos llenos + mínimo 4 letras
    private var todosValidos: Bool {
        let lista = nombresNormalizados
        guard lista.count == maxJugadores else { return false }
        return lista.allSatisfy { !$0.isEmpty && cuentaLetras($0) >= 4 }
    }

    /// Duplicados case-insensitive, basado en normalizado
    private var hayDuplicados: Bool {
        let lista = nombresNormalizados.map { $0.lowercased() }
        return Set(lista).count != lista.count
    }

    // -----------------------------------------------------------
    // UI
    // -----------------------------------------------------------

    var body: some View {

        VStack(spacing: 16) {

            // ---------------------------------------------------
            // Header
            // ---------------------------------------------------

            Text("Ingresar jugadores")
                .font(.title.bold())

            Text("Mínimo 4 letras por nombre")
                .font(.caption)
                .foregroundColor(.secondary)

            // ---------------------------------------------------
            // Lista de jugadores
            // ---------------------------------------------------

            List {
                ForEach(nombres.indices, id: \.self) { index in

                    TextField(
                        "Jugador \(index + 1)",
                        text: Binding(
                            get: {
                                nombres[index]
                            },
                            set: { nuevo in

                                // ✅ UX: capitaliza “en vivo” la primera letra
                                //    - Sin tocar tu normalización “real”
                                //    - Sin romper la regla de 4 letras ni duplicados
                                nombres[index] = capitalizarSuaveEnVivo(nuevo)
                            }
                        )
                    )
                    .textInputAutocapitalization(.words)   // ayuda del teclado
                    .autocorrectionDisabled()              // evita autocorrecciones raras
                    .focused($foco, equals: index)
                    .submitLabel(index == maxJugadores - 1 ? .done : .next)
                    .onSubmit {
                        // Mover foco al siguiente input o cerrar teclado
                        if index < maxJugadores - 1 {
                            foco = index + 1
                        } else {
                            foco = nil
                        }
                    }
                }
            }

            // ---------------------------------------------------
            // Botón continuar
            // ---------------------------------------------------

            Button {

                // -----------------------------
                // Validación al tocar Continuar
                // -----------------------------

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

                // -----------------------------
                // OK → navegar a Ruleta
                // -----------------------------

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

        // -------------------------------------------------------
        // Navegación moderna (iOS 16+)
        // -------------------------------------------------------
        .navigationDestination(isPresented: $irARuleta) {
            RuletaView(jugadores: nombresNormalizados)
        }

        // -------------------------------------------------------
        // Alertas
        // -------------------------------------------------------
        .alert("Revisar nombres", isPresented: $mostrarAlerta) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text(mensajeAlerta)
        }

        // -------------------------------------------------------
        // Autofocus inicial
        // -------------------------------------------------------
        .onAppear {
            foco = 0
        }
    }
}
