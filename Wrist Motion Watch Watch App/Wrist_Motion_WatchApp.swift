//
//  Wrist_Motion_WatchApp.swift
//  Wrist Motion Watch Watch App
//
//  Created by Seungjun Lee on 5/18/26.
//

import SwiftUI

@main
struct Wrist_Motion_Watch_Watch_AppApp: App {

    // MARK: - DI 구성 (앱 수명과 동일한 싱글턴)

    private let sessionManager   = WatchSessionManager()
    private let motionTracker    = MotionTracker()
    private let recordingStorage = WatchRecordingStorage()

    private let transferService: WatchTransferService
    private let startUseCase:    StartRecordingUseCase
    private let stopUseCase:     StopRecordingUseCase

    @State private var recordingViewModel: RecordingViewModel

    init() {
        let transfer = WatchTransferService(sessionManager: sessionManager)
        let start = StartRecordingUseCase(recorder: motionTracker, storage: recordingStorage)
        let stop  = StopRecordingUseCase(
            recorder: motionTracker,
            storage:  recordingStorage,
            transfer: transfer
        )

        let vm = RecordingViewModel(startUseCase: start, stopUseCase: stop)

        // 파일 전송 완료 → ViewModel을 idle 상태로 복귀
        sessionManager.onTransferDidFinish = { [vm] _ in
            Task { @MainActor in vm.transferDidComplete() }
        }

        // iPhone으로부터 녹화 명령 수신 → ViewModel 동작 수행
        sessionManager.onCommandReceived = { [vm] command in
            Task { @MainActor in
                switch command {
                case .start: vm.startRecording()
                case .stop:  vm.stopRecording()
                }
            }
        }

        transferService     = transfer
        startUseCase        = start
        stopUseCase         = stop
        _recordingViewModel = State(wrappedValue: vm)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: recordingViewModel, storage: recordingStorage)
        }
    }
}
