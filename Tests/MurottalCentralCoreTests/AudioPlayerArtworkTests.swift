import AppKit
import MediaPlayer
import XCTest
@testable import MurottalCentralCore

final class AudioPlayerArtworkTests: XCTestCase {

    /// Regresi untuk crash `EXC_BAD_INSTRUCTION` di `*/accessQueue`.
    ///
    /// MediaPlayer memanggil `requestHandler` milik `MPMediaItemArtwork` dari
    /// queue internalnya, **bukan** main thread. Bila closure itu ter-isolasi
    /// `@MainActor` (karena dibuat di konteks MainActor), pemanggilan dari
    /// queue lain akan memicu `dispatch_assert_queue_fail` → SIGILL.
    ///
    /// Tes ini memanggil handler dari background thread, meniru MediaPlayer.
    func testArtworkHandlerIsCallableOffMainThread() async {
        let image = NSImage(size: NSSize(width: 64, height: 64))
        let artwork = AudioPlayer.makeArtwork(from: image)

        let rendered = await Task.detached(priority: .userInitiated) {
            artwork.image(at: NSSize(width: 32, height: 32))
        }.value

        XCTAssertNotNil(rendered)
    }
}
