import AdminDomain
import DesignSystem
import SwiftUI

/// Detail of any record: a bento header, grouped fields and the actions the
/// record allows. Actions need the lock open and a confirmation.
struct RecordDetailView: View {
    @Environment(AppModel.self) private var model
    let recordID: String

    @State private var record: AdminRecord?
    @State private var error: String?
    @State private var pending: AdminAction?

    var body: some View {
        ScrollView {
            if let record {
                VStack(alignment: .leading, spacing: Theme.Space.gap) {
                    header(record)
                    if !record.actions.isEmpty { actions(record) }
                    ForEach(record.sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(tr(section.titleKey))
                                .font(Theme.Font.headline)
                                .foregroundStyle(Theme.ink)
                            ForEach(section.fields) { field in
                                FieldRow(tr(field.labelKey), value: tr(field.value), tone: field.severity.tone)
                                if field.id != section.fields.last?.id {
                                    Divider().overlay(Theme.hairline)
                                }
                            }
                        }
                        .padding(16)
                        .bentoSurface()
                    }
                }
                .padding(.horizontal, Theme.Space.screen)
                .padding(.bottom, Theme.Space.tabBarClearance)
            } else if let error {
                ContentUnavailableView(tr("Could not load"), systemImage: "exclamationmark.triangle", description: Text(error))
            } else {
                LoadingTiles()
            }
        }
        .screenBackground()
        .navigationTitle(record.map { tr($0.page.titleKey) } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { ActionsLockButton() }
        }
        .task(id: model.revision) {
            do {
                let loaded = try await model.service.record(id: recordID)
                withAnimation(Theme.snappy) { record = loaded }
            } catch is CancellationError {
            } catch {
                self.error = error.localizedDescription
            }
        }
        .actionConfirmation($pending) { updated in
            withAnimation(Theme.snappy) { record = updated }
        }
    }

    private func header(_ record: AdminRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                SymbolBadge(record.symbol, tone: record.status?.severity.tone ?? .brand, size: Theme.Size.badge)
                Spacer()
                if let status = record.status { StatusChip(status) }
            }
            Text(record.title)
                .font(Theme.Font.title2)
                .foregroundStyle(Theme.ink)
                .textSelection(.enabled)
            if !record.subtitle.isEmpty {
                Text(record.subtitle)
                    .font(Theme.Font.subheadline)
                    .foregroundStyle(Theme.inkSoft)
            }
            HStack {
                if let module = record.module {
                    Label(tr(module.titleKey), systemImage: module.symbol)
                }
                Spacer()
                Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            .font(Theme.Font.caption)
            .foregroundStyle(Theme.inkSoft)
            HStack {
                Text("ID \(record.id)")
                    .font(Theme.Font.caption.monospaced())
                    .foregroundStyle(Theme.inkSoft)
                    .textSelection(.enabled)
                Spacer()
                if let trailing = record.trailing {
                    Text(trailing)
                        .font(Theme.Font.rowNumber)
                        .foregroundStyle(Theme.goldText)
                }
            }
        }
        .padding(18)
        .bentoSurface(radius: Theme.Radius.card)
    }

    private func actions(_ record: AdminRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !model.actionsEnabled {
                Label(tr("Actions are off. Unlock with the lock button to use them."), systemImage: "lock.fill")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            LazyVGrid(columns: bentoColumns, spacing: 10) {
                ForEach(record.actions) { action in
                    Button {
                        pending = action
                    } label: {
                        Label(tr(action.kindKey), systemImage: action.symbol)
                            .font(Theme.Font.subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity, minHeight: Theme.Size.actionCapsule)
                            .foregroundStyle(action.isDestructive ? Theme.danger : Theme.onGold)
                            .background(action.isDestructive ? AnyShapeStyle(Theme.danger.opacity(0.12)) : AnyShapeStyle(Theme.goldGradient),
                                        in: .capsule)
                    }
                    .buttonStyle(PressScale())
                    .disabled(!model.actionsEnabled)
                    .opacity(model.actionsEnabled ? 1 : 0.45)
                }
            }
        }
    }
}

// MARK: - Confirmation

extension View {
    /// Asks before any write, runs it, and reports the result.
    func actionConfirmation(_ pending: Binding<AdminAction?>,
                            onDone: @escaping (AdminRecord) -> Void = { _ in }) -> some View {
        modifier(ActionConfirmation(pending: pending, onDone: onDone))
    }
}

private struct ActionConfirmation: ViewModifier {
    @Environment(AppModel.self) private var model
    @Binding var pending: AdminAction?
    let onDone: (AdminRecord) -> Void
    @State private var failure: String?

    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                pending.map { tr($0.kindKey) + "?" } ?? "",
                isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
                titleVisibility: .visible,
                presenting: pending
            ) { action in
                Button(tr(action.kindKey), role: action.isDestructive ? .destructive : nil) {
                    run(action)
                }
                Button(tr("Cancel"), role: .cancel) {}
            } message: { action in
                Text(model.actionsEnabled
                     ? (action.isDestructive ? tr("This changes live data. The user may be notified.") : tr("This changes live data."))
                     : tr("Actions are off. Unlock them first."))
            }
            .alert(tr("Action failed"), isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button(tr("OK"), role: .cancel) {}
            } message: {
                Text(failure ?? "")
            }
    }

    private func run(_ action: AdminAction) {
        Task {
            if !model.actionsEnabled {
                guard await model.unlockActions() else { return }
            }
            do {
                let updated = try await model.perform(action)
                action.isDestructive ? Haptic.warn.fire() : Haptic.success.fire()
                onDone(updated)
            } catch {
                Haptic.error.fire()
                failure = error.localizedDescription
            }
        }
    }
}
