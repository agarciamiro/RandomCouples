import SwiftUI
import UIKit

struct ContentView: View {

    // ✅ Texto MVP1 (restaurado)
    private let mensajeMVP = "MVP de APP “RandomCouples” 🔥: equipos PAR/IMPAR, turnos, registro de bolas y bola 8 con tronera cantada + pantalla final. ¡A jugar! 🎱, al 21/12/2025"

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {

                    Spacer().frame(height: 90)

                    // ✅ Logo (NO depende de Assets: si no existe "bola8", dibuja una bola 8)
                    LogoBola8()
                        .frame(width: 120, height: 120)
                        .padding(.bottom, 18)

                    // Título
                    Text("RandomCouples")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.primary)

                    // Subtítulo
                    Text("Tu asignador aleatorio de equipos y turnos")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 6)

                    Spacer()

                    // Botón Comenzar -> PartidaView
                    NavigationLink {
                        PartidaView()
                    } label: {
                        Text("Comenzar")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 22)

                    // ✅ Mensaje MVP (centrado, difuminado, mismo tamaño que firma)
                    Text(mensajeMVP)
                        .font(.footnote)
                        .foregroundColor(Color.gray.opacity(0.55))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.85)
                        .padding(.horizontal, 24)
                        .padding(.top, 10)

                    Spacer().frame(height: 22)

                    // Firma
                    Text("by AGMP")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
        }
    }
}

// MARK: - Logo Bola 8 (con fallback)
private struct LogoBola8: View {

    // Si existe en Assets una imagen llamada EXACTAMENTE "bola8", se usa.
    private var existeAssetBola8: Bool {
        UIImage(named: "bola8") != nil
    }

    var body: some View {
        Group {
            if existeAssetBola8 {
                Image("bola8")
                    .resizable()
                    .scaledToFit()
            } else {
                ZStack {
                    Circle().fill(Color.black)

                    // Borde suave
                    Circle()
                        .stroke(Color.white.opacity(0.20), lineWidth: 3)

                    // Círculo blanco del centro
                    Circle()
                        .fill(Color.white)
                        .frame(width: 46, height: 46)

                    // Número 8
                    Text("8")
                        .font(.system(size: 34, weight: .black))
                        .foregroundColor(.black)
                }
                .scaledToFit()
            }
        }
        .accessibilityLabel("Bola 8")
    }
}
