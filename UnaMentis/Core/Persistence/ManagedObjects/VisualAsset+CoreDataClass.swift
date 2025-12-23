// UnaMentis - VisualAsset Core Data Class
// Represents visual content (images, diagrams, equations) linked to curriculum topics
//
// Follows IMS Content Packaging and W3C accessibility standards

import Foundation
import CoreData

@objc(VisualAsset)
public class VisualAsset: NSManagedObject {

}

// MARK: - Convenience Properties

extension VisualAsset {

    /// The visual asset type as an enum
    public var visualType: VisualAssetType {
        get {
            VisualAssetType(rawValue: type ?? "image") ?? .image
        }
        set {
            type = newValue.rawValue
        }
    }

    /// The display mode as an enum
    public var visualDisplayMode: VisualDisplayMode {
        get {
            VisualDisplayMode(rawValue: displayMode ?? "persistent") ?? .persistent
        }
        set {
            displayMode = newValue.rawValue
        }
    }

    /// Whether this visual should be displayed for the given segment index
    public func isActiveForSegment(_ segmentIndex: Int) -> Bool {
        // Reference assets don't have timing - they're shown on demand
        guard !isReference else { return false }

        // If no timing specified, the visual is always active
        guard startSegment >= 0 && endSegment >= 0 else { return true }

        return segmentIndex >= startSegment && segmentIndex <= endSegment
    }

    /// Check if this asset matches a search query (for barge-in requests)
    public func matchesQuery(_ query: String) -> Bool {
        let lowercaseQuery = query.lowercased()

        // Check title
        if let title = title?.lowercased(), title.contains(lowercaseQuery) {
            return true
        }

        // Check keywords
        if let keywords = keywords as? [String] {
            for keyword in keywords {
                if keyword.lowercased().contains(lowercaseQuery) {
                    return true
                }
            }
        }

        // Check alt text
        if let alt = altText?.lowercased(), alt.contains(lowercaseQuery) {
            return true
        }

        return false
    }

    /// Get image data - from cache or needs download
    public func getImageData() -> Data? {
        // First check cached data
        if let cached = cachedData {
            return cached
        }

        // If we have a local path, try to load from bundle
        if let localPath = localPath {
            let url = URL(fileURLWithPath: localPath)
            return try? Data(contentsOf: url)
        }

        // Otherwise, caller needs to download from remoteURL
        return nil
    }
}

// MARK: - Fetch Requests

extension VisualAsset {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VisualAsset> {
        return NSFetchRequest<VisualAsset>(entityName: "VisualAsset")
    }

    /// Fetch all embedded (non-reference) assets for a topic
    @nonobjc public class func fetchEmbeddedAssets(for topic: Topic) -> NSFetchRequest<VisualAsset> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "topic == %@ AND isReference == NO", topic)
        request.sortDescriptors = [NSSortDescriptor(key: "startSegment", ascending: true)]
        return request
    }

    /// Fetch all reference assets for a topic
    @nonobjc public class func fetchReferenceAssets(for topic: Topic) -> NSFetchRequest<VisualAsset> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "topic == %@ AND isReference == YES", topic)
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        return request
    }

    /// Fetch assets active for a specific segment
    @nonobjc public class func fetchAssetsForSegment(_ segmentIndex: Int, topic: Topic) -> NSFetchRequest<VisualAsset> {
        let request = fetchRequest()
        request.predicate = NSPredicate(
            format: "topic == %@ AND isReference == NO AND startSegment <= %d AND endSegment >= %d",
            topic, segmentIndex, segmentIndex
        )
        request.sortDescriptors = [NSSortDescriptor(key: "startSegment", ascending: true)]
        return request
    }
}
