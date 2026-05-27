import SwiftUI

struct TodoRow: View {
    let item: TodoItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(item.isCompleted ? .green : .gray)
                .onTapGesture {
                    withAnimation(.snappy) {
                        item.isCompleted.toggle()
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                Text(item.createdAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}
