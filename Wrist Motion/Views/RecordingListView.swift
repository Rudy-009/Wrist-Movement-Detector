//
//  RecordingListView.swift
//  Wrist Motion
//
//  Created by Seungjun Lee on 5/18/26.
//

import SwiftUI

struct RecordingListView: View {

    @State var viewModel: RecordingListViewModel

    var body: some View {
        List {
            if viewModel.recordings.isEmpty {
                ContentUnavailableView(
                    "녹화 없음",
                    systemImage: "waveform.slash",
                    description: Text("Apple Watch에서 녹화를 시작하세요.")
                )
            } else {
                ForEach(viewModel.recordings) { session in
                    NavigationLink(value: session) {
                        RecordingRowView(session: session)
                    }
                }
                .onDelete { offsets in
                    for i in offsets {
                        viewModel.delete(sessionID: viewModel.recordings[i].id)
                    }
                }
            }
        }
        .navigationTitle("녹화 목록")
        .navigationDestination(for: RecordingSession.self) { session in
            RecordingDetailView(
                viewModel: RecordingDetailViewModel(
                    session:    session,
                    repository: viewModel.repository
                )
            )
        }
        .onAppear {
            viewModel.load()
        }
    }
}

// MARK: - Row

struct RecordingRowView: View {

    let session: RecordingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.headline)
            HStack(spacing: 8) {
                Label(durationText, systemImage: "clock")
                Label("\(session.sampleCount)개", systemImage: "waveform")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var durationText: String {
        let total = Int(session.duration)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
