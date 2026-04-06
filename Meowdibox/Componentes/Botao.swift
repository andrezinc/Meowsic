//
//  Botao.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 20/03/26.
//
import SpriteKit
import SwiftUI

struct Botao: Identifiable {
    let id: UUID = .init()
    let icone: String
    let som: String
    let textura: String
    var tamanho: CGFloat = 50
}
