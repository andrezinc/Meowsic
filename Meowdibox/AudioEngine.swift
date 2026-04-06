import AVFoundation

@MainActor
final class AudioEngine {
    static let shared = AudioEngine()

    private let engine = AVAudioEngine()
    private var players: [Int: AVAudioPlayerNode] = [:]

    let loopDuration: Double = 16
    var cicloDuration: Double = 0

    private var anchorSampleTime: AVAudioFramePosition?

    private init() {
        configurarSessao()
        iniciarEngine()
    }

    private func configurarSessao() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("❌ AudioSession: \(error)")
        }
    }

    private func iniciarEngine() {
        do {
            _ = engine.mainMixerNode
            try engine.start()
        } catch {
            print("❌ Engine start: \(error)")
        }
    }

    private var sampleRate: Double {
        engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
    }

    private var exactLoopFrames: AVAudioFrameCount {
        AVAudioFrameCount(round(sampleRate * loopDuration))
    }

    func preparar(slot: Int, soundName: String, type: String = "wav") {
        remover(slot: slot)

        guard let url = Bundle.main.url(forResource: soundName, withExtension: type) else {
            print("❌ Arquivo não encontrado: \(soundName).\(type)")
            return
        }

        guard let file = try? AVAudioFile(forReading: url) else {
            print("❌ Não conseguiu ler: \(soundName).\(type)")
            return
        }

        let format = file.processingFormat
        let totalFrames = AVAudioFrameCount(file.length)

        guard let tempBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else {
            print("❌ Falha ao criar buffer temp")
            return
        }

        do {
            try file.read(into: tempBuffer)
        } catch {
            print("❌ Falha ao ler arquivo: \(error)")
            return
        }

        let targetFrames = AVAudioFrameCount(round(format.sampleRate * loopDuration))
        let framesToUse = min(targetFrames, tempBuffer.frameLength)

        guard let loopBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToUse) else {
            print("❌ Falha ao criar buffer de loop")
            return
        }

        loopBuffer.frameLength = framesToUse

        for ch in 0 ..< Int(format.channelCount) {
            guard let src = tempBuffer.floatChannelData?[ch],
                  let dst = loopBuffer.floatChannelData?[ch] else { continue }
            memcpy(dst, src, Int(framesToUse) * MemoryLayout<Float>.size)
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)

        players[slot] = player
        player.scheduleBuffer(loopBuffer, at: nil, options: .loops)

        guard let renderTime = engine.mainMixerNode.lastRenderTime,
              renderTime.isSampleTimeValid
        else {
            player.play()
            print("⚠️ Sem renderTime válido; tocando imediatamente")
            return
        }

        let engineRate = sampleRate
        let loopFramesInEngineTime = AVAudioFramePosition(round(engineRate * loopDuration))
        let now = renderTime.sampleTime

        if let anchor = anchorSampleTime {
            let elapsed = max(0, now - anchor)
            let framesIntoLoop = elapsed % loopFramesInEngineTime
            let framesToNext = (framesIntoLoop == 0) ? 0 : (loopFramesInEngineTime - framesIntoLoop)
            let nextBoundary = now + framesToNext

            let startTime = AVAudioTime(sampleTime: nextBoundary, atRate: engineRate)
            player.play(at: startTime)

            print("🎵 Slot \(slot) entra em \(Double(framesToNext) / engineRate)s")
        } else {
            let startSample = now + AVAudioFramePosition(round(engineRate * 0.02))
            anchorSampleTime = startSample

            let startTime = AVAudioTime(sampleTime: startSample, atRate: engineRate)
            player.play(at: startTime)

            print("⚓ Nova âncora criada no sample \(startSample)")
        }

        print("✅ Slot \(slot) → \(soundName) (\(framesToUse) frames)")
    }

    func tocar(slot: Int) {
        guard let player = players[slot] else { return }
        guard !player.isPlaying else { return }
        player.play()
    }

    func setMute(slot: Int, muted: Bool) {
        players[slot]?.volume = muted ? 0 : 1.0
    }

    func isMuted(slot: Int) -> Bool {
        (players[slot]?.volume ?? 1.0) == 0
    }

    func remover(slot: Int) {
        guard let player = players[slot] else { return }

        player.stop()
        engine.detach(player)
        players.removeValue(forKey: slot)

        if players.isEmpty {
            anchorSampleTime = nil
            print("⚓ Sem gatos ativos → âncora zerada")
        }
    }

    func temPlayer(slot: Int) -> Bool {
        players[slot] != nil
    }

    func estaTocando(slot: Int) -> Bool {
        players[slot]?.isPlaying ?? false
    }

    func pararTudo() {
        for slot in players.keys {
            remover(slot: slot)
        }
        anchorSampleTime = nil
    }

    func pausarTudo() {}

    func resumirTudo() {}
}
