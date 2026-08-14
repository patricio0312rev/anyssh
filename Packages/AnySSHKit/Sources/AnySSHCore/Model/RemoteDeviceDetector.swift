public enum RemoteDeviceDetector {
    public static func detect(platform: String, model: String?, product: String?) -> RemoteDeviceType {
        let value = "\(model ?? "") \(product ?? "")".lowercased()
        if platform.lowercased().contains("darwin") {
            if value.contains("macmini") { return .macMini }
            if value.contains("macstudio") { return .macStudio }
            if value.contains("macpro") { return .macPro }
            if value.contains("macbook") { return .laptop }
            if value.contains("imac") { return .desktop }
            return .unknown
        }
        if value.contains("virtual") || value.contains("vmware") || value.contains("kvm") {
            return .unknown
        }
        if value.contains("server") { return .server }
        if value.contains("raspberry") || value.contains("pc") { return .pc }
        return .unknown
    }
}
