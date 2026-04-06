import SpriteKit

@MainActor
final class Gato: SKSpriteNode {
    weak var model: GameModel?
    let slot: Int
    var nomeSound: String = ""
    var isSoundPaused: Bool = false
    var isCustomizado: Bool = false
    let originalSize: CGSize

    private var audio: AudioEngine {
        AudioEngine.shared
    }

    init(slot: Int, posicaoInicial: CGPoint = .zero) {
        self.slot = slot
        let texture = SKTexture(imageNamed: "Default")
        let scaledSize = CGSize(
            width: texture.size().width * 0.045,
            height: texture.size().height * 0.045
        )
        originalSize = scaledSize
        super.init(texture: texture, color: .clear, size: scaledSize)
        position = posicaoInicial
        name = "gato"
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Executar (chamado pelo GameScene a cada ciclo)

    func executar() {
        guard isCustomizado, !nomeSound.isEmpty, !isSoundPaused else { return }
        run(SKAction.scaleX(to: 1, duration: 2))
    }

    // MARK: - Aplicar textura e som (drag & drop)

    func changeTextureSound(textureName: String, soundName: String) {
        guard let model = model else { return }
        model.sounds.removeAll { $0 == nomeSound }

        removeAction(forKey: "playingAnimation")
        childNode(withName: "loadingIndicator")?.removeFromParent()

        audio.preparar(slot: slot, soundName: soundName)

        let newTexture = SKTexture(imageNamed: textureName)
        texture = newTexture
        nomeSound = soundName
        isSoundPaused = false
        isCustomizado = true
        alpha = 1.0
        size = originalSize

        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        run(SKAction.sequence([scaleUp, scaleDown]))
    }

    // MARK: - Toggle som (tap)

    func toggleSound() {
        guard isCustomizado, !nomeSound.isEmpty else { return }

        isSoundPaused.toggle()
        audio.setMute(slot: slot, muted: isSoundPaused)

        if isSoundPaused {
            removeAction(forKey: "playingAnimation")
            run(SKAction.group([
                SKAction.fadeAlpha(to: 0.5, duration: 0.2),
                SKAction.scale(to: 1.0, duration: 0.1),
            ]))
        } else {
            run(SKAction.fadeAlpha(to: 1.0, duration: 0.2))
            // dança retoma no próximo ciclo de mostrarCarregamento
        }
    }

    func mute() {
        isSoundPaused = true
        audio.setMute(slot: slot, muted: true)
        removeAction(forKey: "playingAnimation")
        run(SKAction.group([
            SKAction.fadeAlpha(to: 0.5, duration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.1),
        ]))
    }

    func noMute() {
        isSoundPaused = false
        audio.setMute(slot: slot, muted: false)
        run(SKAction.fadeAlpha(to: 1, duration: 0.2))
        // dança retoma no próximo ciclo de mostrarCarregamento
    }

    // MARK: - Reset (swipe para baixo)

    func resetComAnimacao() {
        guard isCustomizado else { return }

        audio.remover(slot: slot)
        removeAction(forKey: "playingAnimation")
        childNode(withName: "loadingIndicator")?.removeFromParent()

        texture = SKTexture(imageNamed: "Default")
        size = originalSize
        nomeSound = ""
        isSoundPaused = false
        isCustomizado = false
        alpha = 1.0
    }

    func reset() {
        audio.remover(slot: slot)
        removeAction(forKey: "playingAnimation")
        childNode(withName: "loadingIndicator")?.removeFromParent()

        texture = SKTexture(imageNamed: "Default")
        size = originalSize
        nomeSound = ""
        isSoundPaused = false
        isCustomizado = false
        alpha = 1.0
    }

    // MARK: - Indicador de carregamento

    /// Chamado a cada frame pelo GameScene.update().
    /// Mostra o indicador enquanto o som está agendado mas ainda não é audível.
    /// Cria o node filho apenas uma vez — evita spam de criação a cada frame.
    func mostrarCarregamento() {
        // Gatos sem som atribuído não exibem indicador
        guard isCustomizado, !nomeSound.isEmpty else {
            removeAction(forKey: "playingAnimation")
            childNode(withName: "loadingIndicator")?.removeFromParent()
            return
        }

        if !audio.estaTocando(slot: slot) {
            if childNode(withName: "loadingIndicator") == nil {
                let texture = SKTexture(imageNamed: "carregamento")
                let scaledSize = CGSize(
                    width: texture.size().width * 0.03,
                    height: texture.size().height * 0.03
                )

                let carregamento = SKShapeNode(rectOf: scaledSize)
                carregamento.name = "loadingIndicator"
                carregamento.fillTexture = texture
                carregamento.position = position
                carregamento.position.y -= size.height / 2 + 90
                carregamento.position.x -= 111 * CGFloat(slot + 1)
                carregamento.fillColor = .white
                carregamento.strokeColor = .clear
                carregamento.zPosition = 1
                carregamento.run(SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.rotate(byAngle: .pi / 4, duration: 0.2),
                    ])
                ))
                addChild(carregamento)
            }
        } else {
            // Áudio audível — remove indicador
            childNode(withName: "loadingIndicator")?.removeFromParent()
            // Inicia dança apenas uma vez (evita reiniciar toda frame)
            if !isSoundPaused, action(forKey: "playingAnimation") == nil {
                run(SKAction.repeatForever(
                    SKAction.sequence([
                        SKAction.scaleY(to: 1.15, duration: 0.3),
                        SKAction.scaleY(to: 1.0,  duration: 0.3),
                    ])
                ), withKey: "playingAnimation")
            }
        }
    }
}
