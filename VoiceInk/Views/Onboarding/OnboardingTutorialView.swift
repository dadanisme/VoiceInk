import SwiftUI
import KeyboardShortcuts

struct OnboardingTutorialView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var hotkeyManager: HotkeyManager
    @State private var scale: CGFloat = 0.8
    @State private var opacity: CGFloat = 0
    @State private var transcribedText: String = ""
    @State private var isTextFieldFocused: Bool = false
    @State private var showingShortcutHint: Bool = true
    @FocusState private var isFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Reusable background
                OnboardingBackgroundView()
                
                HStack(spacing: 0) {
                    // Left side - Tutorial instructions
                    VStack(alignment: .leading, spacing: Spacing.page) {
                        // Title and description
                        VStack(alignment: .leading, spacing: Spacing.section) {
                            Text("Try It Out!")
                                .font(.largeTitle)
                                .dynamicTypeSize(.large ... .xxLarge)
                                .foregroundStyle(.primary)

                            Text("Let's test your VoiceInk setup.")
                                .font(.titleEmphasis)
                                .foregroundStyle(.secondary)
                                .lineSpacing(4)
                        }

                        // Keyboard shortcut display
                        VStack(alignment: .leading, spacing: Spacing.group) {
                            HStack {
                                Text("Your Shortcut")
                                    .font(.titleEmphasis)
                                    .foregroundStyle(.primary)
                            }

                            if hotkeyManager.selectedHotkey1 == .custom,
                               let shortcut = KeyboardShortcuts.getShortcut(for: .toggleMiniRecorder) {
                                KeyboardShortcutView(shortcut: shortcut)
                                    .scaleEffect(1.2)
                            } else if hotkeyManager.selectedHotkey1 != .none && hotkeyManager.selectedHotkey1 != .custom {
                                Text(hotkeyManager.selectedHotkey1.displayName)
                                    .font(.titleEmphasis)
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.horizontal, Spacing.section)
                                    .padding(.vertical, Spacing.standard)
                                    .background(Color.primary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }

                        // Instructions
                        VStack(alignment: .leading, spacing: Spacing.group) {
                            ForEach(1...4, id: \.self) { step in
                                instructionStep(number: step, text: getInstructionText(for: step))
                            }
                        }

                        Spacer()

                        // Continue button
                        Button {
                            hasCompletedOnboarding = true
                        } label: {
                            Text("Complete Setup")
                                .frame(minWidth: 200)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(transcribedText.isEmpty)

                        SkipButton(text: "Skip for now") {
                            hasCompletedOnboarding = true
                        }
                    }
                    .padding(Spacing.page)
                    .frame(width: geometry.size.width * 0.5)
                    
                    // Right side - Interactive area
                    VStack {
                        // Magical text editor area
                        ZStack {
                            // Glowing background
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.controlBackground.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.separatorColor, lineWidth: 1)
                                )
                                .shadow(color: Color.accentColor.opacity(0.1), radius: 15, x: 0, y: 0)

                            // Text editor with custom styling
                            TextEditor(text: $transcribedText)
                                .font(.largeTitle)
                                .dynamicTypeSize(.large ... .xxLarge)
                                .focused($isFocused)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundStyle(.primary)
                                .padding(Spacing.group)

                            // Placeholder text with magical appearance
                            if transcribedText.isEmpty {
                                VStack(spacing: Spacing.section) {
                                    // HIG: decorative — size is layout-critical, not typography
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 36, weight: .regular, design: .default))
                                        .foregroundStyle(.tertiary)

                                    Text("Click here and start speaking...")
                                        .font(.titleEmphasis)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .allowsHitTesting(false)
                            }

                            // Subtle animated border
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.accentColor.opacity(isFocused ? 0.4 : 0.1),
                                            Color.accentColor.opacity(isFocused ? 0.2 : 0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .animation(.easeInOut(duration: 0.3), value: isFocused)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(Spacing.page)
                    .frame(width: geometry.size.width * 0.5)
                }
            }
        }
        .onAppear {
            animateIn()
            isFocused = true
        }
    }
    
    private func getInstructionText(for step: Int) -> String {
        switch step {
        case 1: return "Click the text area on the right"
        case 2: return "Press your shortcut key"
        case 3: return "Speak something"
        case 4: return "Press your shortcut key again"
        default: return ""
        }
    }
    
    private func instructionStep(number: Int, text: String) -> some View {
        HStack(spacing: Spacing.group) {
            Text("\(number)")
                .font(.titleEmphasis)
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.accentColor.opacity(0.2)))
                .overlay(
                    Circle()
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )

            Text(text)
                .font(.rowTitle.weight(.medium))
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1
            opacity = 1
        }
    }
} 