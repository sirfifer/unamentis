// UnaMentis - Assistant Tab View
// Container view with segmented control for To-Do and Reading List
//
// Part of UI/Assistant

import SwiftUI

// MARK: - Assistant Segment

/// The segments available in the Assistant tab
public enum AssistantSegment: String, CaseIterable, Identifiable {
    case todo = "To-Do"
    case readingList = "Reading"

    public var id: String { rawValue }

    /// SF Symbol icon for the segment
    var iconName: String {
        switch self {
        case .todo: return "checklist"
        case .readingList: return "book.pages"
        }
    }
}

// MARK: - Assistant Tab View

/// Container view for the Assistant tab with segmented navigation
///
/// Contains:
/// - To-Do list for tracking learning tasks
/// - Reading List for uploaded documents
public struct AssistantTabView: View {

    // MARK: - State

    @State private var selectedSegment: AssistantSegment = .todo

    // MARK: - Body

    public var body: some View {
        // Switch between the two views based on segment
        // Each has its own NavigationStack to maintain separate navigation state
        Group {
            switch selectedSegment {
            case .todo:
                TodoListView()
            case .readingList:
                NavigationStack {
                    ReadingListView()
                        .navigationTitle("Reading List")
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            segmentedPicker
        }
    }

    // MARK: - Subviews

    private var segmentedPicker: some View {
        VStack(spacing: 0) {
            Picker("Assistant Section", selection: $selectedSegment) {
                ForEach(AssistantSegment.allCases) { segment in
                    Text(segment.rawValue)
                        .tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()
        }
        .background(.bar)
    }
}

// MARK: - Preview

#Preview {
    AssistantTabView()
}
