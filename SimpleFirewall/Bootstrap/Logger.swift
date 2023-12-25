import OSLog

extension Logger {
    static let loggingSubsystem: String = "com.yueyi.TravelMode"
    
    static let app = Logger(subsystem: Self.loggingSubsystem, category: "APP")
    static let ui = Logger(subsystem: Self.loggingSubsystem, category: "UI")
    static let database = Logger(subsystem: Self.loggingSubsystem, category: "Database")
    static let dataModel = Logger(subsystem: Self.loggingSubsystem, category: "DataModel")
}
