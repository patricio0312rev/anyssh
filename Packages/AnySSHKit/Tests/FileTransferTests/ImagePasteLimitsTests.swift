import Testing

@testable import FileTransfer

@Suite struct ImagePasteLimitsTests {
    private let limits = ImagePasteLimits.standard

    @Test func aSmallScreenshotFitsAsIs() {
        #expect(limits.fits(byteCount: 900_000, width: 1179, height: 2048))
    }

    @Test func tooManyBytesDoesNotFit() {
        #expect(!limits.fits(byteCount: limits.maxBytes + 1, width: 100, height: 100))
    }

    @Test func aLongEdgeOverTheCapDoesNotFit() {
        #expect(!limits.fits(byteCount: 1, width: 1320, height: 2868))
    }

    @Test func qualitiesStepDownSoTheFirstFitIsTheSharpest() {
        #expect(!limits.jpegQualities.isEmpty)
        #expect(limits.jpegQualities == limits.jpegQualities.sorted(by: >))
    }
}
