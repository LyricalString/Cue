import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Activar la app
app.setActivationPolicy(.accessory)

app.run()
