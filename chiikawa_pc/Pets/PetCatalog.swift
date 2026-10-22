//
//  PetCatalog.swift
//  chiikawa_pc
//

import Foundation

struct PetSpecies: Identifiable, Hashable {
    let id: String
    let displayName: String
}

enum PetCatalog {
    static let all: [PetSpecies] = [
        PetSpecies(id: "chiikawa", displayName: "Chiikawa"),
        PetSpecies(id: "hachiware", displayName: "Hachiware"),
        PetSpecies(id: "usagi", displayName: "Usagi"),
        PetSpecies(id: "momonga", displayName: "Momonga"),
        PetSpecies(id: "kurimanju", displayName: "Kurimanju"),
        PetSpecies(id: "rakko", displayName: "Rakko"),
        PetSpecies(id: "shisa", displayName: "Shisa"),
        PetSpecies(id: "siren", displayName: "Siren"),
        PetSpecies(id: "anoko", displayName: "Anoko"),
        PetSpecies(id: "dekatsuyo", displayName: "Dekatsuyo"),
        PetSpecies(id: "furuhonya", displayName: "Furuhonya"),
    ]
}
