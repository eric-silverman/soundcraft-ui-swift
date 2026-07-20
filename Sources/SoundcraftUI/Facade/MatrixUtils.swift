import Combine
import Foundation

/// Switch an AUX/matrix slot between a regular AUX bus and a matrix bus.
///
/// The slot itself is always switched. If it is currently stereo-linked, the
/// linked neighbour slot is switched as well, so a linked pair always stays
/// consistent (both AUX or both matrix). Matrix buses are only available on the Ui24R.
///
/// - Parameter value: `true` to switch to matrix, `false` to switch back to a regular AUX bus
func setMatrixMode(conn: MixerConnection, store: MixerStore, bus: Int, value: Bool) {
    // always switch the slot itself
    conn.setdBool("a.\(bus - 1).matrix", value)

    // also switch the stereo-linked neighbour, if the slot is currently linked.
    // store.state is a CurrentValueSubject, so `.first()` completes synchronously —
    // the local cancellable keeps the subscription alive for that one emission.
    var cancellable: AnyCancellable?
    cancellable = store.stereoIndex(channelType: .aux, channel: bus)
        .first()
        .sink { stereoIndex in
            if let linkedBus = getLinkedChannelNumber(bus, stereoIndex: stereoIndex) {
                conn.setdBool("a.\(linkedBus - 1).matrix", value)
            }
            cancellable?.cancel()
        }
}
