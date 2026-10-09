import Foundation

struct DeviceIdentity: Equatable {
    var name: String?
    var companyID: UInt16?
    var nameFromAdvertisement = false

    static func cleanedName(_ value: String?) -> String? {
        guard let value else { return nil }
        let cleaned = value.components(separatedBy: .controlCharacters)
            .joined(separator: " ").split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return cleaned.isEmpty ? nil : String(cleaned.prefix(120))
    }

    static func companyIdentifier(from data: Data?) -> UInt16? {
        guard let data, data.count >= 2 else { return nil }
        let bytes = Array(data.prefix(2))
        return UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
    }

    func merging(localName: String?, peripheralName: String?, manufacturerData: Data?) -> DeviceIdentity {
        let advertised = Self.cleanedName(localName)
        let resolvedName = advertised ?? (nameFromAdvertisement ? name : nil) ?? Self.cleanedName(peripheralName) ?? name
        return DeviceIdentity(
            name: resolvedName,
            companyID: Self.companyIdentifier(from: manufacturerData) ?? companyID,
            nameFromAdvertisement: advertised != nil || nameFromAdvertisement
        )
    }
}

enum BluetoothCompanyRegistry {
    static let names: [String: String] = {
        guard let url = Bundle.main.url(forResource: "BluetoothCompanyIdentifiers", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let names = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return names
    }()

    static func name(for identifier: UInt16) -> String {
        names[String(identifier)] ?? String(format: "Unknown manufacturer (0x%04X)", identifier)
    }
}
