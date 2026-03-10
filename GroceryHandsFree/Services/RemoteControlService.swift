import Foundation
import MediaPlayer

@MainActor
final class RemoteControlService {
    enum RemoteAction {
        case advanceItem
        case repeatInstruction
    }

    private let commandCenter: MPRemoteCommandCenter
    private var isConfigured = false
    private var onAdvanceItem: (() -> Void)?
    private var onRepeatInstruction: (() -> Void)?

    init(commandCenter: MPRemoteCommandCenter = .shared()) {
        self.commandCenter = commandCenter
    }

    func configure(onAdvanceItem: @escaping () -> Void, onRepeatInstruction: @escaping () -> Void) {
        self.onAdvanceItem = onAdvanceItem
        self.onRepeatInstruction = onRepeatInstruction

        guard !isConfigured else {
            print("[RemoteControl] Already configured, updating handlers only")
            return
        }

        registerSupportedCommands()
        registerUnsupportedCommands()
        isConfigured = true
        print("[RemoteControl] Configured command handlers")
    }

    func tearDown() {
        guard isConfigured else { return }

        let supportedCommands: [MPRemoteCommand] = [
            commandCenter.nextTrackCommand,
            commandCenter.playCommand,
            commandCenter.previousTrackCommand,
            commandCenter.togglePlayPauseCommand
        ]
        let unsupportedCommands: [MPRemoteCommand] = [
            commandCenter.pauseCommand,
            commandCenter.stopCommand,
            commandCenter.changePlaybackPositionCommand,
            commandCenter.seekForwardCommand,
            commandCenter.seekBackwardCommand,
            commandCenter.skipForwardCommand,
            commandCenter.skipBackwardCommand,
            commandCenter.enableLanguageOptionCommand,
            commandCenter.disableLanguageOptionCommand,
            commandCenter.changeRepeatModeCommand,
            commandCenter.changeShuffleModeCommand,
            commandCenter.ratingCommand,
            commandCenter.likeCommand,
            commandCenter.dislikeCommand,
            commandCenter.bookmarkCommand
        ]

        (supportedCommands + unsupportedCommands).forEach { command in
            command.removeTarget(nil)
        }

        isConfigured = false
        print("[RemoteControl] Removed command handlers")
    }

    private func registerSupportedCommands() {
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.handleSupported(action: .advanceItem, commandName: "nextTrack") ?? .commandFailed
        }

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.handleSupported(action: .repeatInstruction, commandName: "play") ?? .commandFailed
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.handleSupported(action: .repeatInstruction, commandName: "previousTrack") ?? .commandFailed
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.handleSupported(action: .repeatInstruction, commandName: "togglePlayPause") ?? .commandFailed
        }
    }

    private func registerUnsupportedCommands() {
        registerUnsupported(commandCenter.pauseCommand, name: "pause")
        registerUnsupported(commandCenter.stopCommand, name: "stop")
        registerUnsupported(commandCenter.changePlaybackPositionCommand, name: "changePlaybackPosition")
        registerUnsupported(commandCenter.seekForwardCommand, name: "seekForward")
        registerUnsupported(commandCenter.seekBackwardCommand, name: "seekBackward")
        registerUnsupported(commandCenter.skipForwardCommand, name: "skipForward")
        registerUnsupported(commandCenter.skipBackwardCommand, name: "skipBackward")
        registerUnsupported(commandCenter.enableLanguageOptionCommand, name: "enableLanguageOption")
        registerUnsupported(commandCenter.disableLanguageOptionCommand, name: "disableLanguageOption")
        registerUnsupported(commandCenter.changeRepeatModeCommand, name: "changeRepeatMode")
        registerUnsupported(commandCenter.changeShuffleModeCommand, name: "changeShuffleMode")
        registerUnsupported(commandCenter.ratingCommand, name: "rating")
        registerUnsupported(commandCenter.likeCommand, name: "like")
        registerUnsupported(commandCenter.dislikeCommand, name: "dislike")
        registerUnsupported(commandCenter.bookmarkCommand, name: "bookmark")
    }

    private func registerUnsupported(_ command: MPRemoteCommand, name: String) {
        command.isEnabled = true
        command.addTarget { _ in
            print("[RemoteControl] Unsupported remote command received: \(name)")
            return .commandFailed
        }
    }

    private func handleSupported(action: RemoteAction, commandName: String) -> MPRemoteCommandHandlerStatus {
        switch action {
        case .advanceItem:
            guard let onAdvanceItem else {
                print("[RemoteControl] Remote command \(commandName) recognized, but no advance handler is attached")
                return .commandFailed
            }
            print("[RemoteControl] Recognized remote command: \(commandName) -> advance item")
            onAdvanceItem()
            return .success
        case .repeatInstruction:
            guard let onRepeatInstruction else {
                print("[RemoteControl] Remote command \(commandName) recognized, but no repeat handler is attached")
                return .commandFailed
            }
            print("[RemoteControl] Recognized remote command: \(commandName) -> repeat instruction")
            onRepeatInstruction()
            return .success
        }
    }
}
