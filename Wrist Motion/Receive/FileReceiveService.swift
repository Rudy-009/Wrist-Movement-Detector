//
//  FileReceiveService.swift
//  Wrist Motion
//
//  Created by Seungjun Lee on 5/18/26.
//

import WatchConnectivity

/// WatchSessionManager.onFileReceived 클로저에서 호출.
/// WCSessionFile → ImportRecordingUseCase로 위임.
@MainActor
final class FileReceiveService {

    private let importUseCase: ImportRecordingUseCase

    init(importUseCase: ImportRecordingUseCase) {
        self.importUseCase = importUseCase
    }

    func handle(file: WCSessionFile) {
        Task { @MainActor in
            try? importUseCase.execute(
                tempFileURL: file.fileURL,
                metadata:    file.metadata ?? [:]
            )
        }
    }
}
