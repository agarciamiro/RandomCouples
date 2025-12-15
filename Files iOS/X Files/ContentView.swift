import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

struct HomeView: View {
    var body: some View {
        VStack(spacing: 40) {

            Spacer()

            // Ícono o logo provisional
            Text("🎱")
                .font(.system(size: 120))

            Text("RandomCouples")
                .font(.largeTitle.bold())
                .padding(.top, -20)

            Text("Tu asignador aleatorio de equipos y turnos")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            NavigationLink {
                PartidaView()
            } label: {
                Text("Comenzar")
                    .font(.title2.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .overlay(alignment: .bottomLeading) {
            Text("by AGMP")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.6))
                .padding(.leading, 12)
                .padding(.bottom, 10)
        }
    }
}
