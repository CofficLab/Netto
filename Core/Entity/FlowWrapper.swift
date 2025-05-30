import NetworkExtension

struct FlowWrapper {
//    var flow: NEFilterFlow
    var id: String
    var hostname: String
    var port: String
    var allowed: Bool
    var direction: NETrafficDirection
}
