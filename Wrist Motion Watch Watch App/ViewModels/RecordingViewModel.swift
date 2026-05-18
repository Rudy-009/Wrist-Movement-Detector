//
//  RecordingViewModel.swift
//  Wrist Motion Watch Watch App
//
//  Created by Seungjun Lee on 5/18/26.
//

import Foundation

@Observable
@MainActor
final class RecordingViewModel {

    enum RecordingState {
        case idle
        case recording(startedAt: Date, sessionID: UUID)
        case transferring
        case error(String)
    }

    private(set) var state: RecordingState = .idle

    private let startUseCase: StartRecordingUseCase
    private let stopUseCase:  StopRecordingUseCase

    init(startUseCase: StartRecordingUseCase, stopUseCase: StopRecordingUseCase) {
        self.startUseCase = startUseCase
        self.stopUseCase  = stopUseCase
    }

    func startRecording() {
        do {
            let id = try startUseCase.execute()
            state = .recording(startedAt: Date(), sessionID: id)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func stopRecording() {
        guard case .recording(let startedAt, let sessionID) = state else { return }
        do {
            try stopUseCase.execute(sessionID: sessionID, startedAt: startedAt)
            state = .transferring
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    /// 전송 완료 후 idle로 복귀 (WCSession didFinish 콜백에서 호출 가능)
    func transferDidComplete() {
        state = .idle
    }
}
