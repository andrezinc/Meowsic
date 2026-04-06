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

    /// O AudioEngine cuida do loop internamente via scheduleBuffer(.loops).
    /// Aqui apenas garantimos que o player esteja tocando.
    func executar() {
        guard isCustomizado, !nomeSound.isEmpty, !isSoundPaused else { return }
        // Se por algum motivo o player parou, reinicia sincronizado
        run(SKAction.scaleX(to: 1, duration: 2))
    }

    // MARK: - Aplicar textura e som (drag & drop)

    func changeTextureSound(textureName: String, soundName: String) {
        // Prepara o som no engine (para anterior, carrega novo, toca sync)
        guard let model = model else { return }
        model.sounds.removeAll { $0 == nomeSound }
        audio.preparar(slot: slot, soundName: soundName)

        let newTexture = SKTexture(imageNamed: textureName)
        texture = newTexture
        nomeSound = soundName
        isSoundPaused = false
        isCustomizado = true
        alpha = 1.0
        size = originalSize

        // Feedback visual
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        run(SKAction.sequence([scaleUp, scaleDown]))
    }

    // MARK: - Toggle som (tap)

    func toggleSound() {
        guard isCustomizado, !nomeSound.isEmpty else { return }

        isSoundPaused.toggle()
        // Mute/unmute — o player continua rodando em sync,
        // só não emite som. Ao desmutar, volta no ponto certo.
        audio.setMute(slot: slot, muted: isSoundPaused)

        if isSoundPaused {
            run(SKAction.fadeAlpha(to: 0.5, duration: 0.2))
        } else {
            run(SKAction.fadeAlpha(to: 1.0, duration: 0.2))
        }
    }

    func mute() {
        isSoundPaused = true
        audio.setMute(slot: slot, muted: isSoundPaused)
        run(SKAction.fadeAlpha(to: 0.5, duration: 0.2))
    }

    func noMute() {
        isSoundPaused = false
        audio.setMute(slot: slot, muted: isSoundPaused)
        run(SKAction.fadeAlpha(to: 1, duration: 0.2))
    }

    // MARK: - Reset (swipe para baixo)

    func resetComAnimacao() {
        guard isCustomizado else { return }

        audio.remover(slot: slot)

        let defaultTexture = SKTexture(imageNamed: "Default")
        texture = defaultTexture
        size = originalSize
        nomeSound = ""
        isSoundPaused = false
        isCustomizado = false
        alpha = 1.0
    }

    func reset() {
        audio.remover(slot: slot)

        let defaultTexture = SKTexture(imageNamed: "Default")
        texture = defaultTexture
        size = originalSize
        nomeSound = ""
        isSoundPaused = false
        isCustomizado = false
        alpha = 1.0
    }

    func mostrarCarregamento() {
        if !audio.estaTocando(slot: slot) {
            var carregamento: SKShapeNode
            let texture = SKTexture(imageNamed: "carregamento")
            let scaledSize = CGSize(
                width: texture.size().width * 0.03,
                height: texture.size().height * 0.03
            )
            carregamento = SKShapeNode(rectOf: scaledSize)
            carregamento.fillTexture = texture
            carregamento.position = position
            carregamento.position.y -= size.height / 2 + 90
            carregamento.position.x -= 90 * CGFloat(slot + 1)
            carregamento.fillColor = .white
            carregamento.strokeColor = .clear
            carregamento.zPosition = 1
            addChild(carregamento)
        } else {
            removeAllChildren()
        }
    }
}
