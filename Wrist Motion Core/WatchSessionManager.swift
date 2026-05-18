//
//  WatchSessionManager.swift
//  Wrist Motion
//
//  Created by Seungjun Lee on 5/18/26.
//

import WatchConnectivity

@Observable
final class WatchSessionManager: NSObject {

    var state = WCSessionActivationState.notActivated
    var isRechable: Bool = false

    #if os(iOS)
    /// iPhone 전용: Watch로부터 파일을 수신하면 호출되는 클로저.
    /// FileReceiveService에서 주입.
    var onFileReceived: ((WCSessionFile) -> Void)?
    #endif
    
    override init() {
        super.init()
        guard WCSession.isSupported() else {
            fatalError("Watch Connectivity가 지원되지 않는 기기입니다.")
        }
        WCSession.default.delegate = self
        WCSession.default.activate()
        // let _ = WCSession.default.activationState
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        state = WCSession.default.activationState
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // 세션이 비활성 상태로 전환될 때 (예: 다른 Apple Watch로 전환 중)
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // 세션이 완전히 비활성화됐을 때
        // 재활성
        WCSession.default.activate()
        // 비활성 알림
    }
    #endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        isRechable = WCSession.default.isReachable
    }

    #if os(iOS)
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        onFileReceived?(file)
    }
    #endif
}

extension WatchSessionManager {
    func sendFile(file: URL, metadata: [String : Any]?) {
        WCSession.default.transferFile(file, metadata: metadata)
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: (any Error)?) {
        
    }
}
