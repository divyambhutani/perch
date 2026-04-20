import AppKit

enum NotificationSound {
    static func play() {
        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
}
