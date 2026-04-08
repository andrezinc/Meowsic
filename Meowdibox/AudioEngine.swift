import AVFoundation
import Darwin // mach_absolute_time, mach_timebase_info

// MARK: - Conversão de tempo

private func secondsToMachTicks(_ seconds: Double) -> UInt64 {
    guard seconds > 0 else { return 0 }
    var info = mach_timebase_info_data_t()
    mach_timebase_info(&info)
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

    private var scheduledWallClockStarts: [Int: Double] = [:]

    /// Duração real do loop, lida do primeiro arquivo carregado.
    private(set) var loopDuration: Double = 0
    var cicloDuration: Double = 0

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

    // MARK: - Carregar e agendar

    func preparar(slot: Int, soundName: String, type: String = "wav") {
        remover(slot: slot)

        guard let url = Bundle.main.url(forResource: soundName, withExtension: type) else {
            print("❌ Arquivo não encontrado: \(soundName).\(type)"); return
        }
        guard let file = try? AVAudioFile(forReading: url) else {
            print("❌ Não conseguiu ler: \(soundName).\(type)"); return
        }

        let fileFormat = file.processingFormat
        let fileFrames = AVAudioFrameCount(file.length)

        guard let rawBuffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: fileFrames) else {
            print("❌ Falha ao criar buffer"); return
        }
        rawBuffer.frameLength = fileFrames
        do { try file.read(into: rawBuffer) }
        catch { print("❌ Falha ao ler arquivo: \(error)"); return }

        let fileDuration = Double(fileFrames) / fileFormat.sampleRate
        if loopDuration == 0 { loopDuration = fileDuration }

        // Converte para o formato nativo do hardware (ex: 48000 Hz) para evitar
        // SRC em tempo real, que causa micro-gap na junção do loop.
        let hwFormat = engine.outputNode.inputFormat(forBus: 0)
        let loopBuffer: AVAudioPCMBuffer

        if fileFormat.sampleRate != hwFormat.sampleRate,
           let converter = AVAudioConverter(from: fileFormat, to: hwFormat) {
            let ratio = hwFormat.sampleRate / fileFormat.sampleRate
            let outFrames = AVAudioFrameCount(Double(fileFrames) * ratio)
            guard let converted = AVAudioPCMBuffer(pcmFormat: hwFormat, frameCapacity: outFrames) else {
                print("❌ Falha ao criar buffer convertido"); return
            }
            var convError: NSError?
            var sourceConsumed = false
            converter.convert(to: converted, error: &convError) { _, outStatus in
                if sourceConsumed {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                outStatus.pointee = .haveData
                sourceConsumed = true
                return rawBuffer
            }
            if let e = convError { print("❌ Conversão SRC: \(e)"); return }
            loopBuffer = converted
        } else {
            loopBuffer = rawBuffer
        }

        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: loopBuffer.format)
        players[slot] = player
        player.scheduleBuffer(loopBuffer, at: nil, options: .loops)

        // --- Cálculo wall-clock do momento de entrada ---
        let now = CACurrentMediaTime()
        let wallClockStart: Double

        if let anchor = anchorWallClock {
            let secsIntoLoop = (now - anchor).truncatingRemainder(dividingBy: loopDuration)
            let secsToNext   = (secsIntoLoop < 0.02) ? 0.0 : (loopDuration - secsIntoLoop)
            wallClockStart   = now + secsToNext
        } else {
            wallClockStart  = now
            anchorWallClock = wallClockStart
        }

        scheduledWallClockStarts[slot] = wallClockStart

        let delay = wallClockStart - now
        if delay <= 0.001 {
            player.play()
        } else {
            let futureMach = mach_absolute_time() + secondsToMachTicks(delay)
            player.play(at: AVAudioTime(hostTime: futureMach))
            print("🎵 Slot \(slot) → \(soundName) | entrada em \(String(format: "%.2f", delay))s")
        }
    }

    // MARK: - Controle

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

        if players.isEmpty { anchorWallClock = nil }
    }

    func pararTudo() {
        for slot in Array(players.keys) { remover(slot: slot) }
        anchorWallClock = nil
    }

    func pausarTudo() {
        players.keys.forEach { setMute(slot: $0, muted: true) }
    }

    func resumirTudo() {
        players.keys.forEach { setMute(slot: $0, muted: false) }
    }

    // MARK: - Estado

    func temPlayer(slot: Int) -> Bool { players[slot] != nil }

    func estaTocando(slot: Int) -> Bool {
        guard let player = players[slot], player.isPlaying else { return false }
        guard let wallStart = scheduledWallClockStarts[slot] else { return true }
        return CACurrentMediaTime() >= wallStart
    }

    func tempoRestante(slot: Int) -> Double? {
        guard let wallStart = scheduledWallClockStarts[slot] else { return nil }
        return max(0, wallStart - CACurrentMediaTime())
    }
}

