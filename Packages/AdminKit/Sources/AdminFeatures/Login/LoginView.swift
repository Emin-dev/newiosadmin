import AdminDomain
import DesignSystem
import SwiftUI

struct LoginView: View {
    @Environment(AppModel.self) private var model
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false
    @State private var error: String?
    @FocusState private var focus: Field?

    enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                VStack(spacing: 14) {
                    LogoMark(size: 76)
                    Text("Rentbutik Admin")
                        .font(Theme.Font.largeTitle)
                        .foregroundStyle(Theme.ink)
                    Text(tr("For Rentbutik admins only. Staff and drivers use the Rentbutik app."))
                        .font(Theme.Font.subheadline)
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                VStack(spacing: 0) {
                    TextField(tr("Email"), text: $email)
                        .textContentType(.username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                        .padding(16)
                    Divider().overlay(Theme.hairline)
                    SecureField(tr("Password"), text: $password)
                        .textContentType(.password)
                        .focused($focus, equals: .password)
                        .submitLabel(.go)
                        .onSubmit(submit)
                        .padding(16)
                }
                .bentoSurface(radius: Theme.Radius.group)

                if let error {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.Font.subheadline)
                        .foregroundStyle(Theme.danger)
                        .transition(.opacity)
                }

                Button(action: submit) {
                    if busy { ProgressView().tint(Theme.onGold) } else { Text(tr("Sign in")) }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(busy || email.isEmpty || password.isEmpty)

                SampleDataBadge()
                Text(tr("The new backend is not connected yet. Any email and a password of 4+ characters open the app with sample data."))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, Theme.Space.screen)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
    }

    private func submit() {
        guard !busy, !email.isEmpty, !password.isEmpty else { return }
        busy = true
        error = nil
        Task {
            defer { busy = false }
            do {
                try await model.signIn(email: email, password: password)
                Haptic.success.fire()
            } catch {
                Haptic.error.fire()
                withAnimation(Theme.snappy) { self.error = tr(error.localizedDescription) }
            }
        }
    }
}
