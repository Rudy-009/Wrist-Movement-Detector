//
//  StopRecordingUseCase.swift
//  Wrist Motion Watch Watch App
//
//  Created by Seungjun Lee on 5/18/26.
//

import Foundation

@MainActor
final class StopRecordingUseCase {

    private let recorder: MotionRecorderProtocol
    private let storage:  RecordingStorageProtocol
    private let transfer: RecordingTransferProtocol

    init(
        recorder: MotionRecorderProtocol,
        storage:  RecordingStorageProtocol,
        transfer: RecordingTransferProtocol
    ) {
        self.recorder = recorder
        self.storage  = storage
        self.transfer = transfer
    }

    /// 녹화를 중지하고, 파일로 flush한 후 즉시 iPhone으로 전송 큐에 등록.
    func execute(sessionID: UUID, startedAt: Date) throws {
        recorder.stopRecording()

        let duration = Date().timeIntervalSince(startedAt)
        let (fileURL, sampleCount) = try storage.flush(sessionID: sessionID, startedAt: startedAt)

        let session = RecordingSession(
            id:          sessionID,
            startedAt:   startedAt,
            duration:    duration,
            sampleCount: sampleCount,
            fileName:    fileURL.lastPathComponent,
            samplingRate: 50
        )

        transfer.transfer(fileURL: fileURL, session: session)

        // WCSession.transferFile은 즉시 파일을 복사하므로 temp 파일 삭제 가능
        try? FileManager.default.removeItem(at: fileURL)
    }
}
