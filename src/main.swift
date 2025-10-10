import AppKit

/// Main application entry point

// Initialize NSApplication instance for manual application lifecycle management
let app = NSApplication.shared

// Configure custom application delegate for browser-specific window management
let delegate = PanelAppDelegate()
app.delegate = delegate

// Launch application with standard macOS integration and command line argument support
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
