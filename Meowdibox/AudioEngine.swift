import AVFoundation
import Darwin // mach_absolute_time, mach_timebase_info

// MARK: - Conversão de tempo

/// Converte um intervalo em segundos para unidades mach_absolute_time.
/// CACurrentMediaTime() e mach_absolute_time() compartilham a mesma base,
/// portanto: futureMach = mach_absolute_time() + secondsToMachTicks(delay)
private func secondsToMachTicks(_ seconds: Double) -> UInt64 {
    guard seconds > 0 else { return 0 }
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
    // ticks = nanoseconds * (denom / numer)
    let nanos = UInt64(seconds * 1_000_000_000)
    if info.numer == info.denom { return nanos }
    return (nanos / UInt64(info.numer)) * UInt64(info.denom)
}

// MARK: - AudioEngine

@MainActor
final class AudioEngine {
    static let shared = AudioEngine()

    private let engine = AVAudioEngine()
    private var players: [Int: AVAudioPlayerNode] = [:]

    /// Wall-clock (CACurrentMediaTime) em que cada slot se torna audível.
    /// Comparar CACurrentMediaTime() >= scheduledWallClockStarts[slot]
    /// é a forma confiável de detectar se o áudio já começou —
    /// sem depender de lastRenderTime nem de isSampleTimeValid.
    private var scheduledWallClockStarts: [Int: Double] = [:]

    let loopDuration: Double = 16
    var cicloDuration: Double = 0

    /// Wall-clock do "tempo zero" do grid de loops.
    /// Todos os sons entram em instantes anchor + N * loopDuration.
    private var anchorWallClock: Double?

    private init() {
        configurarSessao()
        iniciarEngine()
    }

    // MARK: - Setup

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

    // MARK: - Carregar e agendar

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
            print("❌ Falha ao criar buffer temp"); return
        }
        do { try file.read(into: tempBuffer) }
        catch { print("❌ Falha ao ler arquivo: \(error)"); return }

        let targetFrames = AVAudioFrameCount(round(format.sampleRate * loopDuration))
        let framesToUse = min(targetFrames, tempBuffer.frameLength)

        guard let loopBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToUse) else {
            print("❌ Falha ao criar buffer de loop"); return
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

        // --- Cálculo wall-clock do momento de entrada ---
        let now = CACurrentMediaTime()
        let wallClockStart: Double

        if let anchor = anchorWallClock {
            let elapsed = now - anchor
            let secsIntoLoop = elapsed.truncatingRemainder(dividingBy: loopDuration)
            // threshold de 20ms: se estamos quase no início do loop, entramos já
            let secsToNext = (secsIntoLoop < 0.02) ? 0.0 : (loopDuration - secsIntoLoop)
            wallClockStart = now + secsToNext
        } else {
            // Primeiro som — pequena folga de 20ms para o engine estar pronto
            wallClockStart = now + 0.02
            anchorWallClock = wallClockStart
        }

        scheduledWallClockStarts[slot] = wallClockStart

        let delay = wallClockStart - now
        if delay <= 0.001 {
            // Entrada imediata (estamos no boundary ou muito perto)
            player.play()
        } else {
            // AVAudioTime(hostTime:) é a API correta para agendamentos wall-clock;
            // funciona independente de isSampleTimeValid.
            let futureMach = mach_absolute_time() + secondsToMachTicks(delay)
            player.play(at: AVAudioTime(hostTime: futureMach))
            print("🎵 Slot \(slot) → \(soundName) | entrada em \(String(format: "%.2f", delay))s")
        }
    }

    // MARK: - Controle de playback

    func tocar(slot: Int) {
        guard let player = players[slot], !player.isPlaying else { return }
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
        scheduledWallClockStarts.removeValue(forKey: slot)

        if players.isEmpty {
            anchorWallClock = nil
        }
    }

    func pararTudo() {
        for slot in Array(players.keys) {
            remover(slot: slot)
        }
        anchorWallClock = nil
    }

    func pausarTudo() {
        for slot in Array(players.keys) {
            setMute(slot: slot, muted: true)
        }
    }

    func resumirTudo() {
        for slot in Array(players.keys) {
            setMute(slot: slot, muted: false)
        }
    }

    // MARK: - Estado

    func temPlayer(slot: Int) -> Bool {
        players[slot] != nil
    }

    /// Retorna `true` somente quando o slot já ultrapassou o seu instante de
    /// início agendado, ou seja, o áudio é auditível neste momento.
    ///
    /// Internamente compara `CACurrentMediaTime()` com o wall-clock registrado
    /// em `preparar()` — sem depender de `lastRenderTime` nem `isSampleTimeValid`,
    /// que são não-confiáveis no iOS.
    func estaTocando(slot: Int) -> Bool {
        guard let player = players[slot], player.isPlaying else { return false }
        guard let wallStart = scheduledWallClockStarts[slot] else { return true }
        return CACurrentMediaTime() >= wallStart
    }

    func tempoRestante(slot: Int) -> Double? {
        guard let wallStart = scheduledWallClockStarts[slot] else { return nil }
        let remaining = wallStart - CACurrentMediaTime()
        return max(0, remaining)
    }
}
