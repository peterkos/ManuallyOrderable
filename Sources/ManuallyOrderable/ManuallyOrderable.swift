
import Foundation
import OrderedCollections
import SwiftData

/// Defines that a type supports manually self-ordering
/// itself within a collection.
///
/// This is needed because SwiftData doesn't currently provide
/// ordered collections.
///
protocol ManuallyOrderable {
    var index: Int? { get set }
}

/// Supports containing collections of types
/// that are manually orderable (i.e., conform to `ManuallyOrderable`
///
/// The collection must be passed into each method, as the model maintains
/// the source of truth w.r.t. the collection, not this protocol.
///
/// Note: SwiftData does gets funky with superclassing, even if this superclass
/// is not _in_ SwiftData. For now, moving to a protocol.
protocol ManuallyOrdering {
    associatedtype Orderable: ManuallyOrderable & Hashable & PersistentModel & AnyObject
    typealias Element = Orderable

    /// Reorders an item (within an array of `Orderable` elements) to a new index
    func reordering(elements: [Element], source: Element, to destIndex: Int) -> [PersistentIdentifier: Int]

    /// Removes an element from an `Orderable` array, re-indexing all existing elements
    /// to handle a gap/offset in indices.
    func reordering(elements: [Element], removing: Element) -> [PersistentIdentifier: Int]
}

extension ManuallyOrdering {
    /// Returns a dict for O(1) updating of a model's index (performed by the callee) knowing its ID.
    /// This is immutable to `elements` because `inout` / returning + modifying in the callee
    /// leads to a nasty "invalid relationship KeyPathWriteableReference" error.
    public func reordering(elements: [Element], source: Element, to destIndex: Int) -> [PersistentIdentifier: Int] {
        // Duplicate so we can modify indices w/o using the array that auto-updates based on those indices
        let destIndex = destIndex
        var orderedSet = order(elements: elements)

        // Put that thing back where it came from, or so HELP me
        _ = orderedSet.remove(source)
        if destIndex > orderedSet.count {
            orderedSet.append(source)
        } else {
            orderedSet.insert(source, at: destIndex)
        }

        return convertToDictionary(orderedSet: orderedSet)
    }

    public func reordering(elements: [Element], removing elementToRemove: Element) -> [PersistentIdentifier: Int] {
        var ordered = order(elements: elements)
        _ = ordered.remove(elementToRemove)
        return convertToDictionary(orderedSet: ordered)
    }

    private func order(elements: [Element]) -> OrderedSet<Element> {
        OrderedSet(
            elements.sorted { lhs, rhs in
                guard let lhsIndex = lhs.index,
                      let rhsIndex = rhs.index
                else {
                    return true
                }
                return lhsIndex < rhsIndex
            }
        )
    }

    private func convertToDictionary(orderedSet: OrderedSet<Element>) -> [PersistentIdentifier: Int] {
        var orderedArray = Array(orderedSet)
        for i in orderedArray.indices {
            orderedArray[i].index = i
        }
        return Dictionary(
            uniqueKeysWithValues: zip(
                orderedArray.map { $0.persistentModelID },
                orderedArray.indices
            )
        )
    }
}
