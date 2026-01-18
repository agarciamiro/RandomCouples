enum TipoEquipo {
    case par
    case impar

    var titulo: String {
        self == .par ? "PAR" : "IMPAR"
    }
}
