import SwiftUI
import PDFKit

struct GameRulesView: View {

    let game: GameID

    var body: some View {
        VStack {
            if let pdfName = game.rulesPDFName,
               let url = Bundle.main.url(forResource: pdfName, withExtension: "pdf") {
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
