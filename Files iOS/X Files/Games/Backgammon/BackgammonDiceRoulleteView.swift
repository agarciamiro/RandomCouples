import SwiftUI
import Foundation

struct BackgammonDiceRouletteView: View {

    let colors: BackgammonColorAssignment

    // Lo dejamos por compatibilidad (para no romper llamadas existentes),
    // pero NO lo usamos para navegar porque saltamos directo al tablero.
    let onContinue: (BackgammonStartDiceResult) -> Void

    @State private var spinning: Bool = false
    @State private var rotation: Double = 0

    @State private var hasResult: Bool = false
    @State private var blackDie: Int = 0
    @State private var whiteDie: Int = 0
    @State private var tieCount: Int = 0

    // ✅ NUEVO: abrir Tablero directo (SIN opcional para evitar pantalla blanca)
    @State private var showBoard: Bool = false
    @State private var boardResult: BackgammonStartDiceResult =
        BackgammonStartDiceResult(blackPlayer: "", whitePlayer: "", blackDie: 1, whiteDie: 2, tieCount: 0)

    var body: some View {

        VStack(spacing: 14) {

            VStack(spacing: 6) {
                Text("Ruleta de inicio")
                    .font(.title2.bold())

                Text("Cada jugador tira 1 dado. El mayor empieza con (mayor + menor).")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 22)
            }
            .padding(.top, 8)

            ZStack {
                DiceWheel(rotation: rotation)
                    .frame(width: 280, height: 280)
                    .shadow(radius: 10, x: 0, y: 6)

                PointerTriangle()
                    .fill(Color.orange.opacity(0.95))
                    .frame(width: 28, height: 18)
                    .offset(y: -150)

                CenterBadge(
                    spinning: spinning,
                    hasResult: hasResult,
                    onSpin: spin
                )
            }
            .padding(.top, 6)

            VStack(spacing: 12) {

                playerBanner(
                    name: colors.blackPlayer,
                    pieceLabel: "NEGRAS",
                    isPieceBlack: true,
                    die: hasResult ? blackDie : nil
                )

                playerBanner(
                    name: colors.whitePlayer,
                    pieceLabel: "BLANCAS",
                    isPieceBlack: false,
                    die: hasResult ? whiteDie : nil
                )
            }
            .padding(.horizontal, 16)

            if hasResult {
                VStack(spacing: 6) {
                    HStack(spacing: 10) {
                        Text("Empieza: \(starterName.uppercased())")
                            .font(.headline.bold())

                        ColorPill(label: pillLabel(for: starterName))
                    }

                    Text("Primer tiro: \(startMajor) + \(startMinor)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if tieCount > 0 {
                        Text("Hubo empate \(tieCount) vez\(tieCount == 1 ? "" : "es") (se repitió automáticamente).")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                .padding(.top, 6)
            } else {
                Text("Toca “Girar” para asignar los dados de inicio.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)
            }

            Spacer(minLength: 0)
        }

        // ✅ NO mostramos título para que jamás se superponga al banner azul.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }

        // ✅ Barra de navegación OPACA
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)

        // ✅ Banner azul ARRIBA
        .safeAreaInset(edge: .top, spacing: 0) {
            banner
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 6)
        }

        // ✅ Botón ABAJO
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if hasResult {
                Button {

                    let result = BackgammonStartDiceResult(
                        blackPlayer: colors.blackPlayer,
                        whitePlayer: colors.whitePlayer,
                        blackDie: blackDie,
                        whiteDie: whiteDie,
                        tieCount: tieCount
                    )

                    // ✅ Opción A: abrir Tablero directo
                    boardResult = result
                    showBoard = true

                    // NO llamamos onContinue(result) para no ir a la pantalla intermedia
                    // onContinue(result)

                } label: {
                    Text("Continuar")
                        .font(.headline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 18)
            }
        }

        // ✅ FULL SCREEN: Tablero directo (ya NO puede quedar blanco)
        .fullScreenCover(isPresented: $showBoard) {
            NavigationStack {
                BackgammonBoardView(startResult: boardResult)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cerrar") { showBoard = false }
                        }
                    }
            }
        }
    }

    // MARK: - Banner

    private var banner: some View {
        HStack(spacing: 10) {
            Image(systemName: "dice.fill").font(.headline)
            Text("Ruleta asignadora de dados de inicio")
                .font(.subheadline.bold())
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Logic

    private var starterName: String {
        (blackDie > whiteDie) ? colors.blackPlayer : colors.whitePlayer
    }

    private var startMajor: Int { max(blackDie, whiteDie) }
    private var startMinor: Int { min(blackDie, whiteDie) }

    private func spin() {
        guard !spinning else { return }

        spinning = true
        hasResult = false
        tieCount = 0

        var b = Int.random(in: 1...6)
        var w = Int.random(in: 1...6)
        while b == w {
            tieCount += 1
            b = Int.random(in: 1...6)
            w = Int.random(in: 1...6)
        }

        blackDie = b
        whiteDie = w

        let extraTurns = Double(Int.random(in: 4...7)) * 360.0
        let targetOffset = Double(Int.random(in: 0...359))
        withAnimation(.easeOut(duration: 1.25)) {
            rotation = extraTurns + targetOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            spinning = false
            hasResult = true
        }
    }

    private func playerBanner(name: String, pieceLabel: String, isPieceBlack: Bool, die: Int?) -> some View {
        let textColor: Color = isPieceBlack ? .black : .white
        let bg: Color = isPieceBlack ? Color(.systemGray5) : Color.black.opacity(0.85)

        return VStack(alignment: .leading, spacing: 6) {
            Text(name.uppercased())
                .font(.headline.bold())
                .foregroundColor(textColor)

            Text(pieceLabel)
                .font(.title3.bold())
                .foregroundColor(textColor)

            Text("Dado: \(die.map(String.init) ?? "—")")
                .font(.subheadline)
                .foregroundColor(textColor.opacity(0.85))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bg)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    // MARK: - Pill

    private func pillLabel(for player: String) -> BackgammonPieceLabel {
        if player == colors.whitePlayer { return .blancas }
        if player == colors.blackPlayer { return .negras }
        return .none
    }

    private enum BackgammonPieceLabel {
        case blancas
        case negras
        case none

        var text: String {
            switch self {
            case .blancas: return "BLANCAS"
            case .negras: return "NEGRAS"
            case .none: return ""
            }
        }

        var bg: Color {
            switch self {
            case .blancas: return Color.black.opacity(0.88)
            case .negras: return Color(.systemGray5)
            case .none: return Color.clear
            }
        }

        var fg: Color {
            switch self {
            case .blancas: return .white
            case .negras: return .black
            case .none: return .clear
            }
        }
    }

    private struct ColorPill: View {
        let label: BackgammonPieceLabel
        var body: some View {
            if label != .none {
                Text(label.text)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(label.bg)
                    .foregroundColor(label.fg)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Wheel (6 segmentos)

private struct DiceWheel: View {
    let rotation: Double

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                DiceSlice(index: i)
            }
            Circle().stroke(Color.black.opacity(0.10), lineWidth: 2)
        }
        .rotationEffect(.degrees(rotation))
    }
}

private struct DiceSlice: View {
    let index: Int

    var body: some View {
        ZStack {
            SliceShape(
                startAngle: .degrees(Double(index) * 60.0 - 90.0),
                endAngle: .degrees(Double(index + 1) * 60.0 - 90.0)
            )
            .fill(index.isMultiple(of: 2) ? Color(.systemGray5) : Color(.systemGray2))
            .overlay(
                SliceShape(
                    startAngle: .degrees(Double(index) * 60.0 - 90.0),
                    endAngle: .degrees(Double(index + 1) * 60.0 - 90.0)
                )
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )

            Text("\(index + 1)")
                .font(.headline.bold())
                .foregroundColor(.primary.opacity(0.85))
                .position(labelPosition)
        }
    }

    private var labelPosition: CGPoint {
        let r: CGFloat = 120
        let mid = (Double(index) * 60.0 + 30.0 - 90.0) * Double.pi / 180.0
        let cx: CGFloat = 140
        let cy: CGFloat = 140
        return CGPoint(
            x: cx + r * CGFloat(cos(mid)),
            y: cy + r * CGFloat(sin(mid))
        )
    }
}

private struct SliceShape: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        p.move(to: center)
        p.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.closeSubpath()
        return p
    }
}

private struct PointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

private struct CenterBadge: View {
    let spinning: Bool
    let hasResult: Bool
    let onSpin: () -> Void

    var body: some View {
        let size: CGFloat = 98

        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: size, height: size)
                .shadow(radius: 6, x: 0, y: 4)

            VStack(spacing: 6) {
                Image(systemName: hasResult ? "checkmark.seal.fill" : "dice.fill")
                    .font(.title3)
                    .foregroundColor(.primary.opacity(0.85))

                Text(hasResult ? "Listo" : (spinning ? "Girando…" : "Girar"))
                    .font(.subheadline.bold())
                    .foregroundColor(.primary.opacity(0.85))
            }
        }
        .contentShape(Circle())
        .onTapGesture {
            if !hasResult && !spinning { onSpin() }
        }
    }
}
