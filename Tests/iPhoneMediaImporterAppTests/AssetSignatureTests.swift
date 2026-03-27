import Foundation
import Testing
@testable import iPhoneMediaImporterApp

struct AssetSignatureTests {
    @Test
    func prefersFingerprintForLooseMatch() {
        let now = Date()
        let left = AssetSignature(
            sourceIdentifier: "left",
            fileName: "IMG_0001.HEIC",
            fileSize: 1024,
            createdAt: now,
            fingerprint: "same-fingerprint"
        )
        let right = AssetSignature(
            sourceIdentifier: "right",
            fileName: "renamed.HEIC",
            fileSize: 2048,
            createdAt: now.addingTimeInterval(60),
            fingerprint: "same-fingerprint"
        )

        #expect(left.looselyMatches(right))
    }

    @Test
    func fallsBackToNameSizeAndDateMatch() {
        let now = Date()
        let left = AssetSignature(
            sourceIdentifier: "left",
            fileName: "IMG_0002.JPG",
            fileSize: 4096,
            createdAt: now,
            fingerprint: nil
        )
        let right = AssetSignature(
            sourceIdentifier: "right",
            fileName: "img_0002.jpg",
            fileSize: 4096,
            createdAt: now.addingTimeInterval(1),
            fingerprint: nil
        )

        #expect(left.looselyMatches(right))
    }
}
