//
//  GameModel.swift
//  Meowdibox
//
//  Created by Andre Castilhano on 16/03/26.
//
import SpriteKit
import SwiftUI

@MainActor
final class GameModel: ObservableObject {
    @Published var numero: Int = 0
    let scene = GameScene()
    @Published var gatos: [Gato] = []
    @Published var pausedSounds: [String] = []
    @Published var sounds: [String] = []
    private var audio: AudioEngine {
        AudioEngine.shared
    }

    func start(viewSize: CGSize) {
        scene.size = viewSize
        scene.scaleMode = .resizeFill
        scene.model = self
        spawnGatos(viewSize: viewSize)
    }

    func changeTexture(textureName: String, soundName: String, posicao: CGPoint) -> Bool {
        let nodesAtPoint = scene.nodes(at: posicao)

        for node in nodesAtPoint {
            if let gato = node as? Gato {
                gato.changeTextureSound(textureName: textureName, soundName: soundName)
                pausedSounds.removeAll { $0 == gato.nomeSound }
                return true
            }
        }
        return false
    }

    func atualizarPausedSounds() {
        var novos: [String] = []
        for gato in gatos {
            if gato.isSoundPaused, !gato.nomeSound.isEmpty {
                novos.append(gato.nomeSound)
            }
        }
        pausedSounds = novos
    }

    private func spawnGatos(viewSize: CGSize) {
        let total = 6
        let spacing: CGFloat = 111

        let totalWidth = CGFloat(total - 1) * spacing
        let startX = (viewSize.width - totalWidth) / 2

        for i in 0 ..< total {
            let x = startX + CGFloat(i) * spacing
            let y = viewSize.height / 2 + 50
            let gatinho = Gato(slot: i, posicaoInicial: CGPoint(x: x, y: y))
            gatinho.model = self
            gatos.append(gatinho)
            scene.addChild(gatinho)
        }
    }

    func pauseAllCats() {
        for gato in gatos {
            gato.isSoundPaused = true
        }
        audio.pausarTudo()
    }

    func startAllCats() {
        for gato in gatos {
            gato.isSoundPaused = false
        }
        audio.resumirTudo()
    }
}
