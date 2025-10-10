import SwiftUI
import AppKit

/// Centralized design token system for consistent visual language.
struct DesignSystem {
    
    struct Colors {
        static let primary = Color.primary
        static let secondary = Color.secondary
        static let tertiary = Color(.tertiaryLabelColor)
        
        static let accent = Color.accentColor
        static let accentSecondary = Color.accentColor.opacity(0.7)
        
        static let backgroundPrimary = Color(.windowBackgroundColor)
        static let backgroundSecondary = Color(.controlBackgroundColor)
        static let backgroundTertiary = Color(.quaternarySystemFill)
        
        static let hover = Color.white.opacity(0.15)
        static let selected = Color.accentColor.opacity(0.15)
        static let pressed = Color.white.opacity(0.3)
        static let focused = Color.accentColor.opacity(0.25)
        
        static let separator = Color(.separatorColor)
        static let border = Color(.separatorColor).opacity(0.3)
        static let shadow = Color.black.opacity(0.1)
        
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
    }
    
    struct Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        
        static let body = Font.body
        static let bodyEmphasized = Font.body.weight(.medium)
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        static let toolbarButton = Font.system(size: 14, weight: .medium)
        static let sidebarHeader = Font.caption.weight(.semibold)
        static let sidebarItem = Font.system(size: 13)
        static let addressBar = Font.body.monospaced()
        static let tabTitle = Font.system(size: 12, weight: .medium)
    }
    
    struct Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 6
        static let tiny: CGFloat = 6
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
        static let xlarge: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        
        static let sidebarPadding: CGFloat = 16
        static let toolbarPadding: CGFloat = 12
        static let contentPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 8
        static let groupSpacing: CGFloat = 16
    }
    
    struct CornerRadius {
        static let none: CGFloat = 0
        static let small: CGFloat = 4
        static let medium: CGFloat = 6
        static let large: CGFloat = 8
        static let xlarge: CGFloat = 12
        static let xxlarge: CGFloat = 16
        
        static let button: CGFloat = 6
        static let card: CGFloat = 8
        static let overlay: CGFloat = 12
        static let popover: CGFloat = 8
    }
    
    struct Shadow {
        static let small = (radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
        static let medium = (radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let large = (radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let overlay = (radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
    
    struct Layout {
        static let windowMinWidth: CGFloat = 375
        static let windowMinHeight: CGFloat = 110
        static let windowDefaultWidth: CGFloat = 1200
        static let windowDefaultHeight: CGFloat = 800
        static let windowDefaultX: CGFloat = 100
        static let windowDefaultY: CGFloat = 100
        
        static let toolbarHeight: CGFloat = 52
        static let tabBarHeight: CGFloat = 28
        static let statusBarHeight: CGFloat = 22
        static let addressBarHeight: CGFloat = 52
        static let sidebarHeaderHeight: CGFloat = 32
        static let sidebarItemHeight: CGFloat = 28
        
        static let sidebarMinWidth: CGFloat = 200
        static let sidebarIdealWidth: CGFloat = 200
        static let sidebarMaxWidth: CGFloat = 200
        static let toolbarMinWidth: CGFloat = 750
        static let addressBarMinWidth: CGFloat = 250
        static let addressBarMaxWidth: CGFloat = 250
        
        static let minTouchTarget: CGFloat = 44
        static let recommendedTouchTarget: CGFloat = 48
        static let comfortableTouchTarget: CGFloat = 52
        
        static let borderWidth: CGFloat = 1.0
        static let separatorWidth: CGFloat = 1.0
    }
    
    struct TabBar {
        static let height: CGFloat = 28
        static let borderWidth: CGFloat = 1.0
        static let minTabWidth: CGFloat = 120
        static let maxTabWidth: CGFloat = 240
        static let tabSpacing: CGFloat = 0
    }
    
    struct AddressBar {
        static let minWidth: CGFloat = 250
        static let maxWidth: CGFloat = 250
        static let height: CGFloat = 52
        static let padding: CGFloat = 8
    }
    
    struct Sidebar {
        static let minWidth: CGFloat = 200
        static let idealWidth: CGFloat = 200
        static let maxWidth: CGFloat = 200
        static let headerHeight: CGFloat = 32
        static let itemHeight: CGFloat = 28
    }
    
    struct Window {
        static let minWidth: CGFloat = 900
        static let minHeight: CGFloat = 600
        static let defaultWidth: CGFloat = 1200
        static let defaultHeight: CGFloat = 800
        static let defaultX: CGFloat = 100
        static let defaultY: CGFloat = 100
        static let statusBarHeight: CGFloat = 22
        
        static let panelShowDelay: Double = 0.1
        static let activationPolicyChangeDelay: Double = 0.2
        static let toolbarConfigurationDelay: Double = 0.05
    }
    
    struct DownloadPopoverConstants {
        static let width: CGFloat = 320
        static let maxHeight: CGFloat = 400
    }
    
    struct ScreenshotPopoverConstants {
        static let width: CGFloat = 320
        static let maxHeight: CGFloat = 300
    }
    
    struct Animation {
        static let instant = SwiftUI.Animation.linear(duration: 0.0)
        static let veryFast = SwiftUI.Animation.easeInOut(duration: 0.05)
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.1)
        static let normal = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.1)
        
        static let spring = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.8,
            blendDuration: 0
        )
        
        static let bouncy = SwiftUI.Animation.spring(
            response: 0.3,
            dampingFraction: 0.6,
            blendDuration: 0
        )
        
        static let tabSwitch = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let sidebarToggle = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let popoverShow = SwiftUI.Animation.easeOut(duration: 0.1)
    }
    
    struct Timing {
        static let instant: Double = 0.0
        static let veryFast: Double = 0.05
        static let fast: Double = 0.1
        static let normal: Double = 0.15
        static let medium: Double = 0.2
        static let slow: Double = 0.25
        static let verySlow: Double = 0.35
        
        static let panelShowDelay: Double = 0.1
        static let activationPolicyChangeDelay: Double = 0.2
        static let toolbarConfigurationDelay: Double = 0.05
        static let cleanupDelay: Double = 0.1
    }
    
    struct Transparency {
        static let none: Double = 1.0
        static let subtle: Double = 0.95
        static let light: Double = 0.9
        static let medium: Double = 0.7
        static let heavy: Double = 0.5
        static let maximum: Double = 0.3
        
        static let windowDefault: Double = 0.9
        static let overlayDefault: Double = 0.8
        static let popoverDefault: Double = 0.95
        
        static let minLevel: Double = 0.3
        static let maxLevel: Double = 1.0
        static let stepSize: Double = 0.1
    }
    
    struct BlurMaterials {
        static let windowBackground = VisualEffectMaterial.behindWindow
        static let contentBackground = VisualEffectMaterial.inWindow
        static let sidebarBackground = VisualEffectMaterial.sidebar
        static let toolbarBackground = VisualEffectMaterial.headerView
        static let popoverBackground = VisualEffectMaterial.popover
        static let menuBackground = VisualEffectMaterial.menu
        static let sheetBackground = VisualEffectMaterial.sheet
        
        static let tabBarMaterial = VisualEffectMaterial.headerView
        static let addressBarMaterial = VisualEffectMaterial.headerView
        static let downloadOverlayMaterial = VisualEffectMaterial.popover
        static let screenshotOverlayMaterial = VisualEffectMaterial.popover
        
        static let defaultBlending = VisualEffectBlendingMode.withinWindow
        static let behindWindowBlending = VisualEffectBlendingMode.behindWindow
    }
    
    struct GlassMorphism {
        static let borderOpacity: Double = 0.18
        static let borderWidth: CGFloat = 0.5
        static let borderGradientOpacity: Double = 0.25
        
        static let backgroundOverlayOpacity: Double = 0.1
        static let backgroundNoise: Double = 0.05
        
        static let glassShadow = (
            radius: CGFloat(20),
            x: CGFloat(0),
            y: CGFloat(8),
            opacity: Double(0.15)
        )
        
        static let floatingShadow = (
            radius: CGFloat(12),
            x: CGFloat(0),
            y: CGFloat(4),
            opacity: Double(0.12)
        )
        
        static let subtleBlur: CGFloat = 5
        static let mediumBlur: CGFloat = 10
        static let heavyBlur: CGFloat = 20
        static let maximumBlur: CGFloat = 40
    }
    
    struct ZIndex {
        static let base: Double = 0
        static let content: Double = 1
        static let sidebar: Double = 10
        static let toolbar: Double = 20
        static let popover: Double = 100
        static let overlay: Double = 200
        static let modal: Double = 1000
    }
    
    private init() {}
}

typealias Colors = DesignSystem.Colors
typealias Typography = DesignSystem.Typography
typealias Spacing = DesignSystem.Spacing
typealias CornerRadius = DesignSystem.CornerRadius
typealias Layout = DesignSystem.Layout
typealias Theme = DesignSystem
typealias UIConstants = DesignSystem
typealias AnimationConstants = DesignSystem
