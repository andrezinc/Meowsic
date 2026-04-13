//
//  BotaoView.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 20/03/26.
//
import SpriteKit
import SwiftUI

struct BotaoView: View {
    @Environment(\.colorScheme) private var colorScheme
    let botao: Botao
    let isDragging: Bool
    let mutado: Bool
    let existSound: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(existSound ? Color.fundoBotao.opacity(0.8) : Color.fundoBotao.opacity(0.2))
            .frame(width: 201/3, height: 146/3)
            .shadow(radius: isDragging ? 18 : 5)
            .overlay(
                iconeDoBotao
            )
            .scaleEffect(isDragging ? 1.12 : 1.0)
    }
    @ViewBuilder
    var iconeDoBotao: some View {
        if !mutado {
            Image(botao.icone)
                .resizable()
                .foregroundStyle(.white)
                .scaledToFit()
                .frame(width: 35)
        } else {
            Image(systemName: "speaker.slash.fill")
                .resizable()
                .foregroundStyle(.white)
                .frame(width: 25,height: 25)
                .padding(20)
        }
    }
}


