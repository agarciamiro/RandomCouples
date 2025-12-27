import Foundation

// MARK: - Tipos base

enum BGSide: String, Codable, Equatable {
    case player1
    case player2
}

enum BGColor: String, Codable, Equatable {
    case white
    case black
}

// MARK: - Configuración

struct BackgammonConfig: Equatable, Codable {

    enum Mode: String, Codable, Equatable {
        case vsCPU
        case twoPlayersAdvisorBoth
        case twoPlayersAdvisorHome
    }

    var mode: Mode
    var homeSide: BGSide

    init(mode: Mode = .twoPlayersAdvisorBoth, homeSide: BGSide = .player1) {
        self.mode = mode
        self.homeSide = homeSide
    }
}

// MARK: - Jugadores

struct BackgammonPlayers: Equatable, Codable {
    var p1: String
    var p2: String

    init(p1: String, p2: String) {
        self.p1 = p1
        self.p2 = p2
    }
}

// MARK: - Asignaciones (LEGACY / compat)

/// Tipo “amplio” para compatibilidad con pantallas antiguas.
/// En el flujo nuevo, normalmente usas BackgammonColorAssignment + BackgammonStartDiceResult.
struct BackgammonAssignment: Equatable, Codable {
    var colors: BackgammonColorAssignment
    var homeSide: BGSide

    init(colors: BackgammonColorAssignment, homeSide: BGSide = .player1) {
        self.colors = colors
        self.homeSide = homeSide
    }

    // Compat: por si en algún lado guardabas white/black directo
    var whitePlayer: String { colors.whitePlayer }
    var blackPlayer: String { colors.blackPlayer }
}

// MARK: - Opening (LEGACY / compat)

struct BackgammonOpening: Equatable, Codable {
    var starter: BGSide
    var openingDice: [Int]
    var tieMultiplier: Int

    init(starter: BGSide, openingDice: [Int], tieMultiplier: Int) {
        self.starter = starter
        self.openingDice = openingDice
        self.tieMultiplier = tieMultiplier
    }
}

// MARK: - Modelos usados por el flujo nuevo (colores + dado de inicio)

struct BackgammonColorAssignment: Equatable, Codable {
    var whitePlayer: String
    var blackPlayer: String

    // Orden “normal”
    init(whitePlayer: String, blackPlayer: String) {
        self.whitePlayer = whitePlayer
        self.blackPlayer = blackPlayer
    }

    // Compatibilidad por si alguien lo llama al revés
    init(blackPlayer: String, whitePlayer: String) {
        self.whitePlayer = whitePlayer
        self.blackPlayer = blackPlayer
    }
}

struct BackgammonStartDiceResult: Equatable, Codable {
    var blackPlayer: String
    var whitePlayer: String
    var blackDie: Int
    var whiteDie: Int
    var tieCount: Int

    // Orden “normal” (como lo tienes tú)
    init(blackPlayer: String, whitePlayer: String, blackDie: Int, whiteDie: Int, tieCount: Int) {
        self.blackPlayer = blackPlayer
        self.whitePlayer = whitePlayer
        self.blackDie = blackDie
        self.whiteDie = whiteDie
        self.tieCount = tieCount
    }

    // Compatibilidad por si en algún archivo lo llamaban con white primero
    init(whitePlayer: String, blackPlayer: String, whiteDie: Int, blackDie: Int, tieCount: Int) {
        self.blackPlayer = blackPlayer
        self.whitePlayer = whitePlayer
        self.blackDie = blackDie
        self.whiteDie = whiteDie
        self.tieCount = tieCount
    }

    var starterIsBlack: Bool { blackDie > whiteDie }
    var starterName: String { starterIsBlack ? blackPlayer : whitePlayer }
    var startMajor: Int { max(blackDie, whiteDie) }
    var startMinor: Int { min(blackDie, whiteDie) }
}
