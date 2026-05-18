//
//  RecordingDetailView.swift
//  Wrist Motion
//
//  Created by Seungjun Lee on 5/18/26.
//

import SwiftUI
import Charts

struct RecordingDetailView: View {

    @State var viewModel: RecordingDetailViewModel

    var body: some View {
        List {
            // MARK: 정보 섹션
            Section("정보") {
                LabeledContent("날짜", value: viewModel.title)
                LabeledContent("길이", value: viewModel.durationText)
                LabeledContent("샘플", value: viewModel.sampleCountText)
            }

            // MARK: 그래프 섹션
            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("로딩 중…")
                        Spacer()
                    }
                    .padding(.vertical)
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } else if !viewModel.samples.isEmpty {
                Section("사용자 가속도") {
                    accelerationChart
                }
                Section("자이로스코프") {
                    gyroChart
                }
                Section("자세 (Attitude)") {
                    attitudeChart
                }
            }
        }
        .navigationTitle("녹화 상세")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSamples()
        }
    }

    // MARK: - Charts

    private var accelerationChart: some View {
        Chart(Array(viewModel.samples.enumerated()), id: \.offset) { i, s in
            LineMark(x: .value("t", i), y: .value("X", s.userAccX))
                .foregroundStyle(by: .value("축", "X"))
            LineMark(x: .value("t", i), y: .value("Y", s.userAccY))
                .foregroundStyle(by: .value("축", "Y"))
            LineMark(x: .value("t", i), y: .value("Z", s.userAccZ))
                .foregroundStyle(by: .value("축", "Z"))
        }
        .chartXAxis(.hidden)
        .frame(height: 120)
    }

    private var gyroChart: some View {
        Chart(Array(viewModel.samples.enumerated()), id: \.offset) { i, s in
            LineMark(x: .value("t", i), y: .value("X", s.rotationRateX))
                .foregroundStyle(by: .value("축", "X"))
            LineMark(x: .value("t", i), y: .value("Y", s.rotationRateY))
                .foregroundStyle(by: .value("축", "Y"))
            LineMark(x: .value("t", i), y: .value("Z", s.rotationRateZ))
                .foregroundStyle(by: .value("축", "Z"))
        }
        .chartXAxis(.hidden)
        .frame(height: 120)
    }

    private var attitudeChart: some View {
        Chart(Array(viewModel.samples.enumerated()), id: \.offset) { i, s in
            LineMark(x: .value("t", i), y: .value("Roll",  s.attitudeRoll))
                .foregroundStyle(by: .value("축", "Roll"))
            LineMark(x: .value("t", i), y: .value("Pitch", s.attitudePitch))
                .foregroundStyle(by: .value("축", "Pitch"))
            LineMark(x: .value("t", i), y: .value("Yaw",   s.attitudeYaw))
                .foregroundStyle(by: .value("축", "Yaw"))
        }
        .chartXAxis(.hidden)
        .frame(height: 120)
    }
}
