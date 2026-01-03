// UnaMentis - Todo Help Sheet
// In-app help for the to-do feature
//
// Part of Todo System

import SwiftUI

/// In-app help for the to-do list explaining features and usage
struct TodoHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Overview Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Track your learning goals and progress. Add items you want to study, and the app will help you stay organized.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Item Types Section
                Section("Item Types") {
                    TodoHelpRow(
                        icon: "target",
                        iconColor: .orange,
                        title: "Learning Goal",
                        description: "A general topic you want to learn. The app will suggest matching curricula."
                    )
                    TodoHelpRow(
                        icon: "book.fill",
                        iconColor: .blue,
                        title: "Curriculum",
                        description: "A full curriculum to work through. Add from the Curriculum tab."
                    )
                    TodoHelpRow(
                        icon: "doc.text.fill",
                        iconColor: .indigo,
                        title: "Topic",
                        description: "A specific topic within a curriculum."
                    )
                    TodoHelpRow(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: .yellow,
                        title: "Review Item",
                        description: "Something to review or practice again, captured during sessions."
                    )
                    TodoHelpRow(
                        icon: "play.circle.fill",
                        iconColor: .green,
                        title: "Continue Session",
                        description: "Auto-created when you stop mid-session. Includes your progress context."
                    )
                }

                // How It Works Section
                Section("How It Works") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 8) {
                            Text("1.")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            Text("Add items manually or they're created automatically during learning sessions.")
                                .font(.subheadline)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("2.")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            Text("Drag to reorder items by priority. Focus on what matters most.")
                                .font(.subheadline)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("3.")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            Text("Swipe left to complete or archive. Swipe right to restore.")
                                .font(.subheadline)
                        }
                        HStack(alignment: .top, spacing: 8) {
                            Text("4.")
                                .font(.headline)
                                .foregroundStyle(.blue)
                            Text("Archived items are kept permanently. Delete to remove forever.")
                                .font(.subheadline)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Auto-Resume Section
                Section("Auto-Resume") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("When you stop a session before completing a topic, the app automatically saves your progress. A 'Continue Session' item is added to your to-do list with context about where you left off.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Label("Includes your place in the curriculum", systemImage: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(.green)

                        Label("Includes recent conversation context", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 4)
                }

                // Voice Commands Section
                Section("Voice Commands") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("During a learning session, you can ask the AI to add items to your to-do list. Try saying:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\"Add machine learning to my to-do list\"")
                                .font(.caption.monospaced())
                            Text("\"I want to review this topic later\"")
                                .font(.caption.monospaced())
                            Text("\"Mark this for practice\"")
                                .font(.caption.monospaced())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                }

                // Tips Section
                Section("Tips") {
                    Label("Tap any item to view details and edit", systemImage: "hand.tap.fill")
                        .foregroundStyle(.blue, .primary)
                    Label("Use the filter menu to view completed or archived items", systemImage: "line.3.horizontal.decrease.circle")
                        .foregroundStyle(.purple, .primary)
                    Label("Pull down to refresh the list", systemImage: "arrow.down.circle.fill")
                        .foregroundStyle(.green, .primary)
                    Label("Items with curriculum links open directly in learning sessions", systemImage: "link")
                        .foregroundStyle(.orange, .primary)
                }
            }
            .navigationTitle("To-Do Help")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

/// Helper row for to-do help items
private struct TodoHelpRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
    }
}

// MARK: - Preview

#Preview {
    TodoHelpSheet()
}
