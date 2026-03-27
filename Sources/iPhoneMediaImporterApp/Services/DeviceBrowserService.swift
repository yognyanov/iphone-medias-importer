import Combine
import Foundation
@preconcurrency import ImageCaptureCore

private let localCameraBrowserMask = ICDeviceTypeMask(
    rawValue: ICDeviceTypeMask.camera.rawValue | ICDeviceLocationTypeMask.local.rawValue
)!

@MainActor
final class DeviceBrowserService: NSObject, ObservableObject {
    @Published private(set) var connectionState: DeviceConnectionState = .searching
    @Published private(set) var activeDeviceName: String?
    @Published private(set) var hasActiveCameraDevice = false
    @Published private(set) var diagnosticDetails = "state=searching; device=-; active=false"

    private let logger = LoggerService()
    private let browser = ICDeviceBrowser()
    private var activeCameraDevice: ICCameraDevice?

    override init() {
        super.init()
        browser.delegate = self
        browser.browsedDeviceTypeMask = localCameraBrowserMask
    }

    func start() {
        if AppMode.current == .demo {
            activeDeviceName = "Demo iPhone"
            hasActiveCameraDevice = true
            connectionState = .connected(name: "Demo iPhone")
            updateDiagnostics(reason: "demo-start")
            logger.info("Device browser started in demo mode.")
            return
        }

        logger.info("Device browser started.")
        connectionState = .searching
        updateDiagnostics(reason: "start")
        browser.start()
    }

    func refresh() {
        if AppMode.current == .demo {
            connectionState = .connected(name: "Demo iPhone")
            activeDeviceName = "Demo iPhone"
            hasActiveCameraDevice = true
            updateDiagnostics(reason: "demo-refresh")
            return
        }

        if let activeCameraDevice {
            let deviceName = activeCameraDevice.name ?? activeDeviceName ?? "iPhone"
            activeDeviceName = deviceName
            hasActiveCameraDevice = true
            if activeCameraDevice.isAccessRestrictedAppleDevice {
                connectionState = .accessRestricted(message: accessRestrictedMessage(for: deviceName))
            } else {
                connectionState = .connected(name: deviceName)
            }
            updateDiagnostics(reason: "refresh-existing-device")

            if !activeCameraDevice.hasOpenSession {
                logger.info("Refreshing current device session for \(deviceName).")
                activeCameraDevice.requestOpenSession(options: nil) { [weak self] error in
                    guard let self else { return }
                    Task { @MainActor in
                        self.handleSessionOpened(
                            withIdentifier: activeCameraDevice.uuidString,
                            deviceName: deviceName,
                            errorMessage: error?.localizedDescription
                        )
                    }
                }
            }
            return
        }

        logger.info("Refreshing device browser.")
        connectionState = .searching
        updateDiagnostics(reason: "refresh-browser")
        browser.stop()
        browser.start()
    }

    func currentDevice() -> ICCameraDevice? {
        activeCameraDevice
    }

    private func isSupported(device: ICDevice) -> Bool {
        let product = (device.productKind ?? "").lowercased()
        let name = (device.name ?? "").lowercased()
        let appleMobileHints = [
            "iphone",
            "ipad",
            "ipod",
            "mobile",
            "phone",
            "apple"
        ]

        return appleMobileHints.contains { hint in
            product.contains(hint) || name.contains(hint)
        }
    }

    private func updateForNoDevice() {
        activeCameraDevice?.delegate = nil
        activeCameraDevice = nil
        activeDeviceName = nil
        hasActiveCameraDevice = false
        connectionState = .disconnected
        updateDiagnostics(reason: "no-device")
    }

    private func accessRestrictedMessage(for deviceName: String) -> String {
        "\(deviceName) bağlı ancak erişim kısıtlı. iPhone kilidini açın ve gerekirse Bu Mac'e Güven onayını verin."
    }

    private func updateDiagnostics(reason: String) {
        let stateLabel: String
        switch connectionState {
        case .searching:
            stateLabel = "searching"
        case .disconnected:
            stateLabel = "disconnected"
        case let .connected(name):
            stateLabel = "connected(\(name))"
        case let .accessRestricted(message):
            stateLabel = "accessRestricted(\(message))"
        }

        diagnosticDetails = "reason=\(reason); state=\(stateLabel); device=\(activeDeviceName ?? "-"); active=\(hasActiveCameraDevice)"
    }
}

extension DeviceBrowserService: ICDeviceBrowserDelegate, ICCameraDeviceDelegate {
    nonisolated func deviceBrowser(_ browser: ICDeviceBrowser, didAdd device: ICDevice, moreComing: Bool) {
        let deviceIdentifier = device.uuidString
        let deviceName = device.name ?? "iPhone"
        let isRestricted = (device as? ICCameraDevice)?.isAccessRestrictedAppleDevice ?? false
        Task { @MainActor in
            self.handleDeviceAdded(
                withIdentifier: deviceIdentifier,
                deviceName: deviceName,
                isRestricted: isRestricted,
                moreComing: moreComing
            )
        }
    }

    nonisolated func deviceBrowser(_ browser: ICDeviceBrowser, didRemove device: ICDevice, moreGoing: Bool) {
        let deviceIdentifier = device.uuidString
        Task { @MainActor in
            self.handleDeviceRemoved(withIdentifier: deviceIdentifier)
        }
    }

    nonisolated func deviceBrowserDidEnumerateLocalDevices(_ browser: ICDeviceBrowser) {
        Task { @MainActor in
            self.handleDeviceEnumerationCompleted()
        }
    }

    nonisolated func device(_ device: ICDevice, didOpenSessionWithError error: (any Error)?) {
        let deviceIdentifier = device.uuidString
        let deviceName = device.name ?? "iPhone"
        let errorMessage = error?.localizedDescription
        Task { @MainActor in
            self.handleSessionOpened(withIdentifier: deviceIdentifier, deviceName: deviceName, errorMessage: errorMessage)
        }
    }

    nonisolated func device(_ device: ICDevice, didCloseSessionWithError error: (any Error)?) {
        let deviceIdentifier = device.uuidString
        let errorMessage = error?.localizedDescription
        Task { @MainActor in
            self.handleSessionClosed(withIdentifier: deviceIdentifier, errorMessage: errorMessage)
        }
    }

    nonisolated func deviceDidBecomeReady(_ device: ICDevice) {
        let deviceIdentifier = device.uuidString
        let deviceName = device.name ?? "iPhone"
        Task { @MainActor in
            self.handleDeviceReady(withIdentifier: deviceIdentifier, deviceName: deviceName)
        }
    }

    nonisolated func device(_ device: ICDevice, didReceiveStatusInformation status: [ICDeviceStatus: Any]) {
        let deviceIdentifier = device.uuidString
        let localizedMessage =
            (status[ICDeviceStatus.localizedStatusNotificationKey] as? String) ??
            (status[ICDeviceStatus.statusNotificationKey] as? String)
        let isRestricted = (device as? ICCameraDevice)?.isAccessRestrictedAppleDevice ?? false
        Task { @MainActor in
            self.handleStatusUpdate(withIdentifier: deviceIdentifier, message: localizedMessage, isRestricted: isRestricted)
        }
    }

    nonisolated func device(_ device: ICDevice, didEncounterError error: (any Error)?) {
        let deviceIdentifier = device.uuidString
        let deviceName = device.name ?? "iPhone"
        let isRestricted = (device as? ICCameraDevice)?.isAccessRestrictedAppleDevice ?? false
        let errorMessage = error?.localizedDescription ?? "Bilinmeyen cihaz hatası."
        Task { @MainActor in
            self.handleDeviceError(
                withIdentifier: deviceIdentifier,
                deviceName: deviceName,
                message: errorMessage,
                isRestricted: isRestricted
            )
        }
    }

    nonisolated func deviceDidBecomeReady(withCompleteContentCatalog device: ICCameraDevice) {
        let deviceIdentifier = device.uuidString
        let deviceName = device.name ?? "iPhone"
        Task { @MainActor in
            self.handleDeviceReady(withIdentifier: deviceIdentifier, deviceName: deviceName)
        }
    }

    nonisolated func cameraDeviceDidRemoveAccessRestriction(_ device: ICDevice) {
        let deviceIdentifier = device.uuidString
        let deviceName = device.name ?? "iPhone"
        Task { @MainActor in
            self.handleAccessRestrictionRemoved(withIdentifier: deviceIdentifier, deviceName: deviceName)
        }
    }

    nonisolated func cameraDeviceDidEnableAccessRestriction(_ device: ICDevice) {
        let deviceIdentifier = device.uuidString
        let deviceName = device.name ?? "iPhone"
        Task { @MainActor in
            self.handleAccessRestrictionEnabled(withIdentifier: deviceIdentifier, deviceName: deviceName)
        }
    }

    nonisolated func didRemove(_ device: ICDevice) {
        let deviceIdentifier = device.uuidString
        Task { @MainActor in
            self.handleDeviceRemoved(withIdentifier: deviceIdentifier)
        }
    }

    nonisolated func cameraDevice(_ camera: ICCameraDevice, didAdd items: [ICCameraItem]) {
        let count = items.count
        Task { @MainActor in
            self.logger.info("Camera content updated: \(count) item eklendi.")
        }
    }

    nonisolated func cameraDevice(_ camera: ICCameraDevice, didRemove items: [ICCameraItem]) {
        let count = items.count
        Task { @MainActor in
            self.logger.info("Camera content updated: \(count) item kaldirildi.")
        }
    }

    nonisolated func cameraDevice(
        _ camera: ICCameraDevice,
        didReceiveThumbnail thumbnail: CGImage?,
        for item: ICCameraItem,
        error: (any Error)?
    ) {}

    nonisolated func cameraDevice(
        _ camera: ICCameraDevice,
        didReceiveMetadata metadata: [AnyHashable: Any]?,
        for item: ICCameraItem,
        error: (any Error)?
    ) {}

    nonisolated func cameraDevice(_ camera: ICCameraDevice, didRenameItems items: [ICCameraItem]) {
        let count = items.count
        Task { @MainActor in
            self.logger.info("Camera content renamed: \(count) item.")
        }
    }

    nonisolated func cameraDeviceDidChangeCapability(_ camera: ICCameraDevice) {
        let deviceIdentifier = camera.uuidString
        let deviceName = camera.name ?? "iPhone"
        let isRestricted = camera.isAccessRestrictedAppleDevice
        Task { @MainActor in
            self.handleStatusUpdate(withIdentifier: deviceIdentifier, message: nil, isRestricted: isRestricted)
            self.logger.info("Camera capability changed for \(deviceName).")
        }
    }

    nonisolated func cameraDevice(_ camera: ICCameraDevice, didReceivePTPEvent eventData: Data) {
        Task { @MainActor in
            self.logger.info("PTP event alindi: \(eventData.count) byte.")
        }
    }
}

@MainActor
private extension DeviceBrowserService {
    func handleDeviceAdded(withIdentifier identifier: String?, deviceName: String, isRestricted: Bool, moreComing: Bool) {
        guard let identifier,
              let device = browser.devices?.first(where: { $0.uuidString == identifier }) else {
            if !moreComing, activeCameraDevice == nil {
                connectionState = .disconnected
            }
            return
        }

        guard let camera = device as? ICCameraDevice else {
            logger.info("Yoksayilan aygit: kamera cihazi degil. name=\(deviceName), productKind=\(device.productKind ?? "-")")
            if !moreComing, activeCameraDevice == nil {
                connectionState = .disconnected
            }
            return
        }

        guard isSupported(device: device) else {
            logger.info("Yoksayilan aygit: desteklenmeyen tur. name=\(deviceName), productKind=\(device.productKind ?? "-")")
            if !moreComing, activeCameraDevice == nil {
                connectionState = .disconnected
            }
            return
        }

        if activeCameraDevice?.uuidString != camera.uuidString {
            activeCameraDevice?.delegate = nil
        }
        activeCameraDevice = camera
        activeCameraDevice?.delegate = self
        activeDeviceName = deviceName
        hasActiveCameraDevice = true

        if isRestricted {
            connectionState = .accessRestricted(message: accessRestrictedMessage(for: deviceName))
            updateDiagnostics(reason: "device-added-restricted")
            logger.info("Supported device connected but access is restricted: \(deviceName).")
        } else {
            connectionState = .connected(name: deviceName)
            updateDiagnostics(reason: "device-added-connected")
            logger.info("Supported device connected: \(deviceName).")
        }
    }

    func handleDeviceRemoved(withIdentifier identifier: String?) {
        guard identifier == activeCameraDevice?.uuidString else {
            return
        }

        logger.info("Active device removed.")
        updateForNoDevice()
    }

    func handleDeviceEnumerationCompleted() {
        if activeCameraDevice == nil {
            connectionState = .disconnected
            updateDiagnostics(reason: "enumeration-completed-no-device")
        }
    }

    func handleSessionOpened(withIdentifier identifier: String?, deviceName: String, errorMessage: String?) {
        guard identifier == activeCameraDevice?.uuidString else {
            return
        }

        if let errorMessage {
            logger.error("Device session open failed for \(deviceName): \(errorMessage)")
            if activeCameraDevice?.isAccessRestrictedAppleDevice == true {
                connectionState = .accessRestricted(message: accessRestrictedMessage(for: deviceName))
            }
            return
        }

        logger.info("Device session opened for \(deviceName).")
        connectionState = .connected(name: deviceName)
        hasActiveCameraDevice = true
        updateDiagnostics(reason: "session-opened")
    }

    func handleSessionClosed(withIdentifier identifier: String?, errorMessage: String?) {
        guard identifier == activeCameraDevice?.uuidString else {
            return
        }

        if let errorMessage {
            logger.error("Device session closed with error: \(errorMessage)")
        } else {
            logger.info("Device session closed.")
        }
    }

    func handleDeviceReady(withIdentifier identifier: String?, deviceName: String) {
        guard identifier == activeCameraDevice?.uuidString else {
            return
        }

        logger.info("Device became ready: \(deviceName).")
        connectionState = .connected(name: deviceName)
        hasActiveCameraDevice = true
        updateDiagnostics(reason: "device-ready")
    }

    func handleStatusUpdate(withIdentifier identifier: String?, message: String?, isRestricted: Bool) {
        guard identifier == activeCameraDevice?.uuidString else {
            return
        }

        if let message, !message.isEmpty {
            logger.info("Device status update: \(message)")
        }

        guard let activeDeviceName else {
            return
        }

        if isRestricted {
            if let message, !message.isEmpty {
                connectionState = .accessRestricted(message: message)
            } else {
                connectionState = .accessRestricted(message: accessRestrictedMessage(for: activeDeviceName))
            }
        } else {
            connectionState = .connected(name: activeDeviceName)
        }
        hasActiveCameraDevice = true
        updateDiagnostics(reason: "status-update")
    }

    func handleDeviceError(withIdentifier identifier: String?, deviceName: String, message: String, isRestricted: Bool) {
        guard identifier == activeCameraDevice?.uuidString else {
            return
        }

        logger.error("Device error for \(deviceName): \(message)")
        if isRestricted {
            connectionState = .accessRestricted(message: accessRestrictedMessage(for: deviceName))
            hasActiveCameraDevice = true
            updateDiagnostics(reason: "device-error-restricted")
            return
        }

        let normalizedMessage = message.lowercased()
        if normalizedMessage.contains("kilidini ac") ||
            normalizedMessage.contains("unlock") ||
            normalizedMessage.contains("guven") ||
            normalizedMessage.contains("trust")
        {
            connectionState = .accessRestricted(message: message)
            hasActiveCameraDevice = true
        } else {
            connectionState = .connected(name: deviceName)
            hasActiveCameraDevice = true
        }
        updateDiagnostics(reason: "device-error")
    }

    func handleAccessRestrictionRemoved(withIdentifier identifier: String?, deviceName: String) {
        guard identifier == activeCameraDevice?.uuidString else {
            return
        }

        logger.info("Access restriction removed for \(deviceName).")
        connectionState = .connected(name: deviceName)
        hasActiveCameraDevice = true
        updateDiagnostics(reason: "restriction-removed")
    }

    func handleAccessRestrictionEnabled(withIdentifier identifier: String?, deviceName: String) {
        guard identifier == activeCameraDevice?.uuidString else {
            return
        }

        logger.info("Access restriction enabled for \(deviceName).")
        connectionState = .accessRestricted(message: accessRestrictedMessage(for: deviceName))
        hasActiveCameraDevice = true
        updateDiagnostics(reason: "restriction-enabled")
    }
}
