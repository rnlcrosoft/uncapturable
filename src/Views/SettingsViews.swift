import SwiftUI

struct BrowserSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(AppConstants.UserInterfaceText.Settings.Browser.pageTitle)
                    .font(Theme.Typography.title)

                Text(AppConstants.UserInterfaceText.Settings.Browser.pageDescription)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondary)

                // Search Engine Information
                VStack(alignment: .leading, spacing: 16) {
                    Text("Search Engine")
                        .font(Theme.Typography.headline)

                    Text("This browser uses Google as the default search engine")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondary)

                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.Colors.accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Google")
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.primary)

                            Text("https://www.google.com/search?q=%s")
                                .font(Theme.Typography.caption2)
                                .foregroundColor(Theme.Colors.secondary)
                        }
                        Spacer()
                        Text("Default")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.backgroundSecondary)
                            .cornerRadius(Theme.CornerRadius.small)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Theme.Colors.accent, lineWidth: 1)
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}



struct WindowSettingsView: View {
    @State private var windowService = WindowService.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(AppConstants.UserInterfaceText.Settings.Window.pageTitle)
                    .font(Theme.Typography.title)
                
                Text(AppConstants.UserInterfaceText.Settings.Window.pageDescription)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondary)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Screen Recording Bypass section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppConstants.UserInterfaceText.Settings.Window.privacyFeaturesTitle)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(AppConstants.UserInterfaceText.Settings.Window.presentationModeLabel, isOn: $windowService.isPresentationModeEnabled)
                                .toggleStyle(.switch)
                            
                            Text(AppConstants.UserInterfaceText.Settings.Window.presentationModeDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                            
                            Toggle(AppConstants.UserInterfaceText.Settings.Window.cleanInterfaceModeLabel, isOn: $windowService.isCleanInterfaceModeEnabled)
                                .toggleStyle(.switch)
                            
                            Text(AppConstants.UserInterfaceText.Settings.Window.trafficLightPreventionDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                            
                            Toggle(AppConstants.UserInterfaceText.Settings.Window.desktopPinningLabel, isOn: $windowService.isPinnedToCurrentDesktop)
                                .toggleStyle(.switch)
                                .disabled(!windowService.isPresentationModeEnabled)
                            
                            Text(AppConstants.UserInterfaceText.Settings.Window.desktopPinningDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                    }
                    
                    // Window Behavior section
                    // VStack(alignment: .leading, spacing: 12) {
                        // Text(AppConstants.UserInterfaceText.Settings.Window.windowBehaviorTitle)
                        //     .font(.headline)
                        
                        // VStack(alignment: .leading, spacing: 8) {
                        //     Toggle(AppConstants.UserInterfaceText.Settings.Window.alwaysOnTopLabel, isOn: $windowService.isAlwaysOnTop)
                        //         .toggleStyle(.switch)
                            
                        //     Text(AppConstants.UserInterfaceText.Settings.Window.alwaysOnTopDescription)
                        //         .font(.caption)
                        //         .foregroundColor(.secondary)
                        //         .padding(.leading, 20)
                        // }
                    // }
                    
                    // Window Transparency section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppConstants.UserInterfaceText.Settings.Window.transparencyTitle)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(AppConstants.UserInterfaceText.Settings.Window.transparencyToggleLabel, isOn: $windowService.isTransparencyEnabled)
                                .toggleStyle(.switch)
                            
                            Text(AppConstants.UserInterfaceText.Settings.Window.transparencyToggleDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                            
                            if windowService.isTransparencyEnabled {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(AppConstants.UserInterfaceText.Settings.Window.transparencyLevelLabel)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(Int((1.0 - windowService.transparencyLevel) * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 20)
                                    
                                    Slider(
                                        value: Binding(
                                            get: { 1.0 - windowService.transparencyLevel },
                                            set: { windowService.transparencyLevel = 1.0 - $0 }
                                        ),
                                        in: 0.1...0.7
                                    ) {
                                        Text("Transparency")
                                    } minimumValueLabel: {
                                        Text("10%")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } maximumValueLabel: {
                                        Text("70%")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.leading, 20)
                                }
                            }
                        }
                    }
                    
                    // Application Behavior section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(AppConstants.UserInterfaceText.Settings.Window.applicationBehaviorTitle)
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(AppConstants.UserInterfaceText.Settings.Window.accessoryModeLabel, isOn: $windowService.isAccessoryApp)
                                .toggleStyle(.switch)
                            
                            Text(AppConstants.UserInterfaceText.Settings.Window.accessoryModeDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
