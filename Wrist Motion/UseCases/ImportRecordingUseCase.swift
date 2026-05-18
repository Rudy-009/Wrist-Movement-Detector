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

        let session = RecordingSession(
            id:          id,
            startedAt:   Date(timeIntervalSince1970: startedAtTS),
            duration:    duration,
            sampleCount: sampleCount,
            fileName:    "WMTF-\(id.uuidString).bin",
            samplingRate: rate
        )
        try repository.save(session: session, from: tempFileURL)

        onRecordingSaved?()
    }
}

enum ImportRecordingError: LocalizedError {
    case malformedMetadata

    var errorDescription: String? {
        "Watch로부터 전달받은 메타데이터 형식이 올바르지 않습니다."
    }
}
