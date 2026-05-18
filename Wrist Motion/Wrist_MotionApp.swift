//
//  Wrist_MotionApp.swift
//  Wrist Motion
//
//  Created by Seungjun Lee on 5/18/26.
//

import SwiftUI
import SwiftData

@main
struct Wrist_MotionApp: App {

    // MARK: - SwiftData 컨테이너

    private let container: ModelContainer = {
        let schema = Schema([RecordingEntity.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    // MARK: - DI 구성

    private let sessionManager: WatchSessionManager
    private let repository:     RecordingRepository
    private let importUseCase:  ImportRecordingUseCase
    private let fileReceiver:   FileReceiveService

    @State private var listViewModel: RecordingListViewModel

    @MainActor
    init() {
        let sm        = WatchSessionManager()
        let fileStore = RecordingFileStore()
        let repo      = RecordingRepository(
            modelContext: ModelContext(container),
            fileStore:    fileStore
        )
        let importUC  = ImportRecordingUseCase(repository: repo)
        let receiver  = FileReceiveService(importUseCase: importUC)

        // WCSession 파일 수신 → FileReceiveService 연결
        sm.onFileReceived = { file in
            Task { @MainActor in receiver.handle(file: file) }
        }

        sessionManager  = sm
        repository      = repo
        importUseCase   = importUC
        fileReceiver    = receiver
        _listViewModel  = State(wrappedValue: RecordingListViewModel(repository: repo))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: listViewModel)
        }
        .modelContainer(container)
    }
}
