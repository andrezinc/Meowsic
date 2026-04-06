import SpriteKit
import SwiftUI

final class GameScene: SKScene {
    weak var model: GameModel?
    var ultimoPlay: TimeInterval = 0
    var playInterval: TimeInterval = 16
    
    let longPressGesture = UILongPressGestureRecognizer()
    
    private var touchedGato: Gato?
    private var holdingGato: Gato?
    private var touchStartPosition: CGPoint = .zero
    private let swipeMinDistance: CGFloat = 40 // mínimo para contar como swipe
    private let tapMaxDistance: CGFloat = 15 // máximo para contar como tap
    private var audio: AudioEngine { AudioEngine.shared }

    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        view.allowsTransparency = true
        longPressGesture.addTarget(self, action: #selector(GameScene.longPress))
        self.view?.addGestureRecognizer(longPressGesture)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let model = model else { return }
            for gato in model.gatos {
                gato.mostrarCarregamento()
            }
        
        if model.sounds.isEmpty{
            audio.pararTudo()
        }
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        touchStartPosition = location

        let nodesAtPoint = nodes(at: location)
        touchedGato = nodesAtPoint.first(where: { $0 is Gato }) as? Gato
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
        
        guard let touch = touches.first,
              let gato = touchedGato,
              let model = model
        else {
            cleanupTouch()
            return
        }


        let endPosition = touch.location(in: self)
        let deltaX = endPosition.x - touchStartPosition.x
        let deltaY = endPosition.y - touchStartPosition.y
        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)

        if deltaY < -swipeMinDistance, abs(deltaY) > abs(deltaX) {
            model.pausedSounds.removeAll { $0 == gato.nomeSound }
            model.sounds.removeAll { $0 == gato.nomeSound }
            gato.resetComAnimacao()
        }

        else if distance < tapMaxDistance {
            
            gato.toggleSound()
            if gato.isSoundPaused {
                model.pausedSounds.append(gato.nomeSound)
            } else {
                model.pausedSounds.removeAll { $0 == gato.nomeSound }
            }
            
        }
        

        cleanupTouch()
    }

    override func touchesCancelled(_: Set<UITouch>, with _: UIEvent?) {
        cleanupTouch()
    }

    private func cleanupTouch() {
        touchedGato = nil
        touchStartPosition = .zero
    }
    
    @objc func longPress(_ sender: UILongPressGestureRecognizer) {
            guard let model = model else {return}
            let longPressLocation = convertPoint(fromView: sender.location(in: self.view))
            sender.minimumPressDuration = 0.4
        
            if sender.state == .began {
                let nodesAtPoint = nodes(at: longPressLocation)
                touchedGato = nodesAtPoint.first(where: { $0 is Gato }) as? Gato
                if (touchedGato != nil) {
                    for gato in model.gatos{
                        if gato != touchedGato{
                            gato.mute()
                            model.pausedSounds.append(gato.nomeSound)
                        }
                    }
                }
            } else if sender.state == .ended {
                for gato in model.gatos{
                    if gato != touchedGato{
                        gato.noMute()
                    }
                    model.pausedSounds.removeAll()
                }
            }
        }
    
}
