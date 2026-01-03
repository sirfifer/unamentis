// UnaMentis - Todo Item Row
// Row component for displaying a single to-do item
//
// Part of Todo System

import SwiftUI

/// Row view for displaying a single to-do item in a list
struct TodoItemRow: View {
    let item: TodoItem
    let onComplete: (() -> Void)?
    let onToggleProgress: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator / complete button
            if let onComplete = onComplete {
                Button {
                    onComplete()
                } label: {
                    Image(systemName: item.status == .completed ? "checkmark.circle.fill" : statusIcon)
                        .font(.title2)
                        .foregroundStyle(statusColor)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.status == .completed ? "Completed" : "Mark as complete")
                .accessibilityHint("Double-tap to complete this item")
            } else {
                Image(systemName: item.status.iconName)
                    .font(.title2)
                    .foregroundStyle(statusColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title ?? "Untitled")
                        .font(.body)
                        .strikethrough(item.status == .completed || item.status == .archived)
                        .foregroundStyle(item.isActive ? .primary : .secondary)

                    Spacer()

                    // Type badge
                    TypeBadge(type: item.itemType)
                }

                // Subtitle row
                HStack(spacing: 8) {
                    // Source indicator
                    if item.source != .manual {
                        Label(item.source.displayName, systemImage: item.source.iconName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Resume indicator
                    if item.hasResumeContext {
                        Label("Resume point", systemImage: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }

                    // Curriculum link indicator
                    if item.isLinkedToCurriculum && !item.hasResumeContext {
                        Label("Linked", systemImage: "link")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    // Date
                    if let date = item.status == .archived ? item.archivedAt : item.updatedAt {
                        Text(formatDate(date))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Notes preview
                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint("Double-tap to edit")
        .accessibilityAddTraits(item.status == .completed ? .isSelected : [])
    }

    // MARK: - Status Properties

    private var statusIcon: String {
        switch item.status {
        case .pending: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .pending: return .secondary
        case .inProgress: return .blue
        case .completed: return .green
        case .archived: return .purple
        }
    }

    // MARK: - Date Formatting

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let title = item.title ?? "Untitled"
        let type = item.itemType.accessibilityDescription
        return "\(type): \(title)"
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        parts.append(item.status.accessibilityDescription)

        if item.hasResumeContext {
            parts.append("has resume point")
        }

        if let notes = item.notes, !notes.isEmpty {
            parts.append("has notes")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Type Badge

struct TypeBadge: View {
    let type: TodoItemType

    var body: some View {
        Label(type.displayName, systemImage: type.iconName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch type.colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "indigo": return .indigo
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        TodoItemRow(
            item: {
                let item = TodoItem()
                return item
            }(),
            onComplete: { },
            onToggleProgress: { }
        )
    }
}
