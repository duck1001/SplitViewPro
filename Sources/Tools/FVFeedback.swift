// FVFeedback.swift
// 对应原版：floatingView.FVFeedback（NSObject）
// 字段：audioPlayer: AVAudioPlayer?、generator: UIImpactFeedbackGenerator?

import UIKit
import AVFAudio

public final class FVFeedback {
    public static let shared = FVFeedback()

    public var audioPlayer: AVAudioPlayer?
    public var generator: UIImpactFeedbackGenerator?

    private let soundPath = "/Library/PreferenceBundles/SplitViewProPrefs.bundle/Sounds/arc_sound.aif"

    private init() {
        generator = UIImpactFeedbackGenerator(style: .light)
        generator?.prepare()
        // rootful / rootless / RootHide 三个位置都试；RootHide 由 .jbroot 符号链接解析。
        let candidates = [
            soundPath,
            "/var/jb" + soundPath,
            Bundle.main.bundlePath + "/Sounds/arc_sound.aif",
        ]
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            if let player = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: path)) {
                audioPlayer = player
                audioPlayer?.prepareToPlay()
                break
            }
        }
    }

    public enum ImpactStyle { case light, medium, heavy }

    public func impact(_ style: ImpactStyle) {
        switch style {
        case .light:  generator = UIImpactFeedbackGenerator(style: .light)
        case .medium: generator = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:  generator = UIImpactFeedbackGenerator(style: .heavy)
        }
        generator?.impactOccurred()
    }

    public func playSound() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
}
