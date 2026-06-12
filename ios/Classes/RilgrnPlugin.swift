import Flutter
import UIKit
import VisionKit

public class RilgrnPlugin: NSObject, FlutterPlugin, VNDocumentCameraViewControllerDelegate {
  private var pendingResult: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "rilgrn", binaryMessenger: registrar.messenger())
    let instance = RilgrnPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "scanDocument":
      self.startDocumentScan(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func startDocumentScan(result: @escaping FlutterResult) {
    if self.pendingResult != nil {
      result(FlutterError(code: "ALREADY_ACTIVE", message: "A document scan is already in progress", details: nil))
      return
    }

    guard VNDocumentCameraViewController.isSupported else {
      result(FlutterError(code: "UNSUPPORTED", message: "Document scanning is not supported on this device", details: nil))
      return
    }

    guard let rootViewController = UIApplication.shared.delegate?.window??.rootViewController else {
      result(FlutterError(code: "NO_ROOT_VC", message: "Could not find root view controller", details: nil))
      return
    }

    self.pendingResult = result

    let scannerViewController = VNDocumentCameraViewController()
    scannerViewController.delegate = self
    
    var topController = rootViewController
    while let presentedViewController = topController.presentedViewController {
        topController = presentedViewController
    }

    topController.present(scannerViewController, animated: true)
  }

  public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
    controller.dismiss(animated: true, completion: nil)

    var paths: [String] = []
    let tempDir = FileManager.default.temporaryDirectory

    for index in 0..<scan.pageCount {
      let image = scan.imageOfPage(at: index)
      if let data = image.jpegData(compressionQuality: 0.8) {
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        do {
          try data.write(to: fileURL)
          paths.append(fileURL.path)
        } catch {
          print("Error saving image: \(error)")
        }
      }
    }

    self.pendingResult?(paths)
    self.pendingResult = nil
  }

  public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    controller.dismiss(animated: true, completion: nil)
    self.pendingResult?(nil)
    self.pendingResult = nil
  }

  public func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
    controller.dismiss(animated: true, completion: nil)
    self.pendingResult?(FlutterError(code: "SCAN_FAILED", message: error.localizedDescription, details: nil))
    self.pendingResult = nil
  }
}
