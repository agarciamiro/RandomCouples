import SwiftUI
import Foundation

// MARK: - Tipos base

enum BGColor: String, CaseIterable, Identifiable, Codable {
    case white
    case black

    var id: String { rawValue }
    var titulo: String { self == .white ? "BLANCAS" : "NEGRAS" }

    var uiColor: Color {
        switch self {
        case .white: return .white
        case .black: return .black
        }
    }
}

enum BGSide: Int, CaseIterable, Identifiable, Codable {
    case player1 = 1
    case player2 = 2

    var id: Int { rawValue }
    var titulo: String { self == .player1 ? "Jugador 1" : "Jugador 2" }
    var opponent: BGSide { self == .player1 ? .player2 : .player1 }
}

// MARK: - Config (BackgammonMode viene de BackgammonMode.swift)

struct BackgammonConfig: Equatable, Codable {
    var mode: BackgammonMode = .twoPlayersDice
    var homeSide: BGSide = .player1

    init(mode: BackgammonMode = .twoPlayersDice, homeSide: BGSide = .player1) {
        self.mode = mode
        self.homeSide = homeSide
    }

    // Codable manual por si BackgammonMode NO es Codable
    enum CodingKeys: String, CodingKey { case mode, homeSide }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let modeKey = try c.decodeIfPresent(String.self, forKey: .mode) ?? "twoPlayersDice"
        self.mode = BackgammonMode.fromStorage(modeKey)
        self.homeSide = try c.decodeIfPresent(BGSide.self, forKey: .homeSide) ?? .player1
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(mode.storageKey, forKey: .mode)
        try c.encode(homeSide, forKey: .homeSide)
    }
}

private extension BackgammonMode {
    var storageKey: String {
        switch self {
        case .twoPlayersDice: return "twoPlayersDice"
        default: return "twoPlayersDice"
        }
    }

    static func fromStorage(_ key: String) -> BackgammonMode {
        switch key {
        case "twoPlayersDice": return .twoPlayersDice
        default: return .twoPlayersDice
        }
    }
}

// MARK: - Players

struct BackgammonPlayers: Equatable, Codable {
    var p1: String
    var p2: String

    init(p1: String = "Jugador 1", p2: String = "Jugador 2") {
        self.p1 = p1
        self.p2 = p2
    }
}

// MARK: - Assignment (tu GameView usa assignment.p1Color/p2Color y color(of:))

struct BackgammonAssignment: Equatable, Codable {
    var p1Color: BGColor
    var p2Color: BGColor

    static let `default` = BackgammonAssignment(p1Color: .white, p2Color: .black)

    init(p1Color: BGColor, p2Color: BGColor) {
        self.p1Color = p1Color
        self.p2Color = p2Color
    }

    // compat
    init(player1: BGColor, player2: BGColor) {
        self.p1Color = player1
        self.p2Color = player2
    }

    func color(for side: BGSide) -> BGColor { side == .player1 ? p1Color : p2Color }
    func color(of side: BGSide) -> BGColor { color(for: side) } // <- arregla "have 'of:' expected 'for:'"
}

// MARK: - ColorAssignment (tu DiceRouletteView usa blackPlayer/whitePlayer)

struct BackgammonColorAssignment: Equatable, Codable {
    var blackSide: BGSide
    var whiteSide: BGSide

    var blackPlayer: String
    var whitePlayer: String

    init(blackSide: BGSide, whiteSide: BGSide, blackPlayer: String, whitePlayer: String) {
        self.blackSide = blackSide
        self.whiteSide = whiteSide
        self.blackPlayer = blackPlayer
        self.whitePlayer = whitePlayer
    }

    init(players: BackgammonPlayers, assignment: BackgammonAssignment) {
        if assignment.p1Color == .black {
            self.blackSide = .player1
            self.whiteSide = .player2
            self.blackPlayer = players.p1
            self.whitePlayer = players.p2
        } else {
            self.blackSide = .player2
            self.whiteSide = .player1
            self.blackPlayer = players.p2
            self.whitePlayer = players.p1
        }
    }
}

// MARK: - StartDiceResult (tu BoardView necesita starterIsBlack/startMajor/startMinor)

struct BackgammonStartDiceResult: Equatable, Codable {
    /// Semántica: die1 = dado de NEGRAS, die2 = dado de BLANCAS
    let die1: Int
    let die2: Int

    /// Cuántos empates hubo antes de resolver
    let tieCount: Int

    init(blackDie: Int, whiteDie: Int, tieCount: Int = 0) {
        self.die1 = BackgammonStartDiceResult.clamp(blackDie)
        self.die2 = BackgammonStartDiceResult.clamp(whiteDie)
        self.tieCount = max(0, tieCount)
    }

    // Compat por si en algún lado lo creas distinto
    init(die1: Int, die2: Int, starts: BGSide) {
        self.die1 = BackgammonStartDiceResult.clamp(die1)
        self.die2 = BackgammonStartDiceResult.clamp(die2)
        self.tieCount = 0
    }

    var starterIsBlack: Bool { die1 > die2 }
    var startMajor: Int { max(die1, die2) }
    var startMinor: Int { min(die1, die2) }

    private static func clamp(_ v: Int) -> Int { min(max(v, 1), 6) }
}

// MARK: - Opening (tu GameView/FirstRollView necesitan starter/openingDice/tieMultiplier)

struct BackgammonOpening: Equatable, Codable {
    var config: BackgammonConfig
    var players: BackgammonPlayers
    var assignment: BackgammonAssignment
    var colors: BackgammonColorAssignment
    var startResult: BackgammonStartDiceResult

    init(config: BackgammonConfig,
         players: BackgammonPlayers,
         assignment: BackgammonAssignment,
         startResult: BackgammonStartDiceResult) {
        self.config = config
        self.players = players
        self.assignment = assignment
        self.colors = BackgammonColorAssignment(players: players, assignment: assignment)
        self.startResult = startResult
    }

    /// Quién empieza (player1/player2) según el ganador de la apertura (negras/blancas)
    var starter: BGSide {
        startResult.starterIsBlack ? colors.blackSide : colors.whiteSide
    }

    /// Dados de apertura ya listos como movimientos (mayor + menor)
    var openingDice: [Int] {
        [startResult.startMajor, startResult.startMinor]
    }

    /// Multiplicador por empates (1 si no hubo empates)
    var tieMultiplier: Int {
        max(1, startResult.tieCount + 1)
    }
}

// MARK: - Board Core Models

enum BGPiece {
    case none
    case white
    case black
}

extension BGPiece {
    init(color: BGColor) {
        switch color {
        case .white: self = .white
        case .black: self = .black
        }
    }
}

struct BGPointStack {
    var piece: BGPiece
    var count: Int
}

// MARK: - Board Setup Factory

struct BGBoardFactory {
    
    static func standardSetup(homeColor: BGColor) -> [Int: BGPointStack] {
        
        var p: [Int: BGPointStack] = [:]
        
        for i in 1...24 {
            p[i] = BGPointStack(piece: .none, count: 0)
        }
        
        let awayColor: BGColor = (homeColor == .black) ? .white : .black
        
        // Casa (abajo): 2 en 24, 5 en 13, 3 en 8, 5 en 6
        p[24] = BGPointStack(piece: BGPiece(color: homeColor), count: 2)
        p[13] = BGPointStack(piece: BGPiece(color: homeColor), count: 5)
        p[8]  = BGPointStack(piece: BGPiece(color: homeColor), count: 3)
        p[6]  = BGPointStack(piece: BGPiece(color: homeColor), count: 5)
        
        // Visita (arriba): 2 en 1, 5 en 12, 3 en 17, 5 en 19
        p[1]  = BGPointStack(piece: BGPiece(color: awayColor), count: 2)
        p[12] = BGPointStack(piece: BGPiece(color: awayColor), count: 5)
        p[17] = BGPointStack(piece: BGPiece(color: awayColor), count: 3)
        p[19] = BGPointStack(piece: BGPiece(color: awayColor), count: 5)
        
        return p
    }
}
