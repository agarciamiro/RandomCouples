import SwiftUI
import PDFKit

struct GameRulesView: View {

    let game: GameID

    var body: some View {
        VStack {
            if let pdfName = game.rulesPDFName,
               let url = findPDF(named: pdfName) {

                PDFKitView(url: url)

            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reglas de \(game.title)")
                            .font(.title2.bold())
                        Text("Aún no hay PDF cargado para este juego.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Reglas")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func findPDF(named name: String) -> URL? {
        // 1) intento normal (raíz del bundle)
        if let u = Bundle.main.url(forResource: name, withExtension: "pdf") {
            return u
        }

        // 2) búsqueda recursiva (funciona aunque esté en subcarpetas)
        guard let bundleURL = Bundle.main.resourceURL else { return nil }
        if let enumerator = FileManager.default.enumerator(at: bundleURL, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.lastPathComponent == "\(name).pdf" {
                    return fileURL
                }
            }
        }
        return nil
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.document = PDFDocument(url: url)
        return v
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
