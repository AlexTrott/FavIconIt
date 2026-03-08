import Foundation

struct ICOEncoder {

    struct IconEntry {
        let width: Int
        let height: Int
        let pngData: Data
    }

    static func encode(entries: [IconEntry]) -> Data {
        var data = Data()

        // ICONDIR header (6 bytes)
        appendUInt16(&data, 0)                          // Reserved
        appendUInt16(&data, 1)                          // Type: 1 = ICO
        appendUInt16(&data, UInt16(entries.count))       // Image count

        // Image data starts after header + all directory entries
        let headerSize = 6 + entries.count * 16
        var currentOffset = headerSize

        // ICONDIRENTRY (16 bytes each)
        for entry in entries {
            data.append(UInt8(entry.width >= 256 ? 0 : entry.width))   // Width (0 = 256)
            data.append(UInt8(entry.height >= 256 ? 0 : entry.height)) // Height (0 = 256)
            data.append(0)                              // No color palette
            data.append(0)                              // Reserved
            appendUInt16(&data, 1)                      // Color planes
            appendUInt16(&data, 32)                     // Bits per pixel
            appendUInt32(&data, UInt32(entry.pngData.count))    // Image data size
            appendUInt32(&data, UInt32(currentOffset))          // Image data offset

            currentOffset += entry.pngData.count
        }

        // Raw PNG data for each entry
        for entry in entries {
            data.append(entry.pngData)
        }

        return data
    }

    private static func appendUInt16(_ data: inout Data, _ value: UInt16) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }

    private static func appendUInt32(_ data: inout Data, _ value: UInt32) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
}
