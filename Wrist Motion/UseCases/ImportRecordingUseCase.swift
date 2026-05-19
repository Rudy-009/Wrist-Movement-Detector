//
//  ImportRecordingUseCase.swift
//  Wrist Motion
//
//  Created by Seungjun Lee on 5/18/26.
//

import Foundation

@MainActor
final class ImportRecordingUseCase {

    private let repository: RecordingRepositoryProtocol

    /// 저장 성공 후 호출 — List 갱신 등에 활용.
    var onRecordingSaved: (() -> Void)?

    /// iPhone에서 stop을 누른 시각. 파일 수신 시 이 시각 이후 샘플을 트리밍.
    var pendingStopAt: Date?

    init(repository: RecordingRepositoryProtocol) {
        self.repository = repository
    }

    /// WCSession metadata를 파싱하여 RecordingSession을 구성하고 영구 저장.
    func execute(tempFileURL: URL, metadata: [String: Any]) throws {
        guard
            let idString    = metadata["sessionID"]   as? String,
            let id          = UUID(uuidString: idString),
            let startedAtTS = metadata["startedAt"]   as? TimeInterval,
            let duration    = metadata["duration"]    as? TimeInterval,
            let sampleCount = metadata["sampleCount"] as? Int,
            let rate        = metadata["samplingRate"] as? Int
        else {
            throw ImportRecordingError.malformedMetadata
        }

        let stopAt = pendingStopAt
        pendingStopAt = nil

        let fileURLToSave: URL
        let finalSampleCount: Int
        let finalDuration: TimeInterval

        if let stopAt {
            let result = try trimFile(
                tempFileURL:    tempFileURL,
                watchStartedAt: Date(timeIntervalSince1970: startedAtTS),
                stopAt:         stopAt,
                sessionID:      id
            )
            fileURLToSave    = result.url
            finalSampleCount = result.sampleCount
            finalDuration    = result.duration
        } else {
            fileURLToSave    = tempFileURL
            finalSampleCount = sampleCount
            finalDuration    = duration
        }

        let session = RecordingSession(
            id:           id,
            startedAt:    Date(timeIntervalSince1970: startedAtTS),
            duration:     finalDuration,
            sampleCount:  finalSampleCount,
            fileName:     "WMTF-\(id.uuidString).bin",
            samplingRate: rate
        )
        try repository.save(session: session, from: fileURLToSave)

        onRecordingSaved?()
    }

    private func trimFile(
        tempFileURL: URL,
        watchStartedAt: Date,
        stopAt: Date,
        sessionID: UUID
    ) throws -> (url: URL, sampleCount: Int, duration: TimeInterval) {
        let validDuration = stopAt.timeIntervalSince(watchStartedAt)
        let allSamples = try MotionSampleSerializer.read(from: tempFileURL)

        guard let firstTimestamp = allSamples.first?.timestamp else {
            return (tempFileURL, 0, 0)
        }

        let trimmed = allSamples.filter { $0.timestamp - firstTimestamp <= validDuration }
        guard !trimmed.isEmpty else { throw ImportRecordingError.trimmedToEmpty }

        // 잘린 샘플 없으면 원본 파일 재사용
        if trimmed.count == allSamples.count {
            let actualDuration = allSamples.last!.timestamp - firstTimestamp
            return (tempFileURL, allSamples.count, actualDuration)
        }

        let actualDuration = trimmed.last!.timestamp - firstTimestamp
        let trimmedURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("WMTF-\(sessionID.uuidString)-trimmed.bin")
        try MotionSampleSerializer.write(trimmed, to: trimmedURL)
        return (trimmedURL, trimmed.count, actualDuration)
    }
}

enum ImportRecordingError: LocalizedError {
    case malformedMetadata
    case trimmedToEmpty

    var errorDescription: String? {
        switch self {
        case .malformedMetadata:
            return "Watch로부터 전달받은 메타데이터 형식이 올바르지 않습니다."
        case .trimmedToEmpty:
            return "정지 시점 이후의 데이터만 포함되어 저장할 샘플이 없습니다."
        }
    }
}
