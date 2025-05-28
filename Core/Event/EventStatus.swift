import Foundation

extension Notification.Name {
    static let willInstall = Notification.Name("willInstall")
    static let willBoot = Notification.Name("willBoot")
    static let didInstall = Notification.Name("didInstall")
    static let didFailWithError = Notification.Name("didFailWithError")
    static let willStart = Notification.Name("willStart")
    static let didStart = Notification.Name("didStart")
    static let willStop = Notification.Name("willStop")
    static let didStop = Notification.Name("didStop")
    static let configurationChanged = Notification.Name("configurationChanged")
    static let needApproval = Notification.Name("needApproval")
    static let error = Notification.Name("error")
    static let willRegisterWithProvider = Notification.Name("willRegisterWithProvider")
    static let didRegisterWithProvider = Notification.Name("didRegisterWithProvider")
}
