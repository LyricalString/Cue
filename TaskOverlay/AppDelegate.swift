import Cocoa
import Carbon

enum TaskPriority: Int, Codable {
    case low = 0
    case medium = 1
    case high = 2
}

struct TaskItem: Codable {
    var id: UUID
    var text: String
    var isCompleted: Bool
    var priority: TaskPriority
    var createdAt: Date
    
    init(id: UUID = UUID(), text: String, isCompleted: Bool = false, priority: TaskPriority = .medium, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var panel: KeyablePanel!
    var statusItem: NSStatusItem!

    var containerView: TaskContainerView!
    var inputField: NSTextField!
    var inputContainer: NSView!
    var headerView: NSView!
    var positionLabel: NSTextField!
    var scrollUpIndicator: NSImageView!
    var scrollDownIndicator: NSImageView!
    var tasksContainer: NSView!
    var taskRows: [EditableTaskRow] = []

    let panelWidth: CGFloat = 340
    let rowHeight: CGFloat = 36
    let inputHeight: CGFloat = 40
    let maxVisibleTasks: Int = 7

    var isUIReady = false
    var isShowingInput = false
    var isRepositioning = false

    var tasks: [TaskItem] = []
    var selectedIndex: Int = 0
    var scrollOffset: Int = 0

    var savedTopLeft: NSPoint?
    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadData()
        setupPanel()
        setupStatusItem()
        setupGlobalHotKey()

        isUIReady = true
        rebuildUI()
        panel.orderOut(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }

    func saveData() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks_v2")
        }
        UserDefaults.standard.set(selectedIndex, forKey: "selectedIndex")
        if let pos = savedTopLeft {
            UserDefaults.standard.set(pos.x, forKey: "panelTopX")
            UserDefaults.standard.set(pos.y, forKey: "panelTopY")
        }
    }

    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "tasks_v2"),
           let decoded = try? JSONDecoder().decode([TaskItem].self, from: data) {
            tasks = decoded
        } else if let oldTasks = UserDefaults.standard.stringArray(forKey: "tasks") {
            tasks = oldTasks.map { TaskItem(text: $0) }
            UserDefaults.standard.removeObject(forKey: "tasks")
        }
        selectedIndex = UserDefaults.standard.integer(forKey: "selectedIndex")
        if selectedIndex >= tasks.count { selectedIndex = max(0, tasks.count - 1) }

        if UserDefaults.standard.object(forKey: "panelTopX") != nil {
            savedTopLeft = NSPoint(
                x: UserDefaults.standard.double(forKey: "panelTopX"),
                y: UserDefaults.standard.double(forKey: "panelTopY")
            )
        }
    }

    func getTopLeft() -> NSPoint {
        return NSPoint(x: panel.frame.minX, y: panel.frame.maxY)
    }

    func setTopLeft(_ topLeft: NSPoint) {
        let newOrigin = NSPoint(x: topLeft.x, y: topLeft.y - panel.frame.height)
        panel.setFrameOrigin(newOrigin)
    }

    func setupPanel() {
        guard let screen = NSScreen.main else { return }

        let defaultTopLeft = NSPoint(x: 20, y: screen.frame.height - 50)
        if savedTopLeft == nil { savedTopLeft = defaultTopLeft }
        let topLeft = savedTopLeft!
        let initialOrigin = NSPoint(x: topLeft.x, y: topLeft.y - 100)

        panel = KeyablePanel(
            contentRect: NSRect(x: initialOrigin.x, y: initialOrigin.y, width: panelWidth, height: 100),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.becomesKeyOnlyIfNeeded = true
        panel.isMovableByWindowBackground = true

        panel.keyHandler = { [weak self] event in
            self?.handleKeyEvent(event)
        }

        containerView = TaskContainerView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: 100))
        containerView.material = .popover
        containerView.state = .active
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 10
        containerView.layer?.masksToBounds = true
        containerView.alphaValue = 0.98
        
        // Subtle border for definition
        containerView.layer?.borderWidth = 0.5
        containerView.layer?.borderColor = NSColor.systemGray.withAlphaComponent(0.15).cgColor

        setupInputField()
        setupHeaderView()
        setupTasksContainer()
        setupScrollIndicators()

        panel.contentView = containerView

        NotificationCenter.default.addObserver(forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
            guard let self = self, !self.isRepositioning else { return }
            self.savedTopLeft = self.getTopLeft()
            self.saveData()
        }

        NotificationCenter.default.addObserver(forName: NSWindow.didResignKeyNotification, object: panel, queue: .main) { [weak self] _ in
            self?.hideOverlay()
        }
    }

    var inputFieldHeightConstraint: NSLayoutConstraint!
    var headerTopConstraint: NSLayoutConstraint!
    var tasksContainerHeightConstraint: NSLayoutConstraint!
    
    func setupInputField() {
        // Create a container for the input field with icon
        inputContainer = NSView()
        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.wantsLayer = true
        inputContainer.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.3).cgColor
        inputContainer.layer?.cornerRadius = 8
        
        // Plus icon
        let icon = NSImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
        icon.contentTintColor = NSColor.tertiaryLabelColor
        
        inputField = NSTextField()
        inputField.placeholderString = "Añadir tarea..."
        inputField.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        inputField.isBordered = false
        inputField.backgroundColor = .clear
        inputField.focusRingType = .none
        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false
        inputField.setAccessibilityLabel("Campo de nueva tarea")
        
        inputContainer.addSubview(icon)
        inputContainer.addSubview(inputField)
        containerView.addSubview(inputContainer)
        
        // Keep reference to container for hiding/showing
        inputContainer.alphaValue = 0.0
        
        inputFieldHeightConstraint = inputContainer.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            inputContainer.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            inputContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            inputContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            inputFieldHeightConstraint,
            
            icon.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 10),
            icon.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 14),
            icon.heightAnchor.constraint(equalToConstant: 14),
            
            inputField.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            inputField.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -10),
            inputField.centerYAnchor.constraint(equalTo: inputContainer.centerYAnchor)
        ])
    }

    var titleLabel: NSTextField!
    
    func setupHeaderView() {
        headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.wantsLayer = true
        
        // Title on the left
        titleLabel = NSTextField(labelWithString: "Tasks")
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = NSColor.secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Counter on the right
        positionLabel = NSTextField(labelWithString: "0/0")
        positionLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        positionLabel.textColor = NSColor.tertiaryLabelColor
        positionLabel.alignment = .right
        positionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(positionLabel)
        containerView.addSubview(headerView)
        
        headerTopConstraint = headerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10)
        
        NSLayoutConstraint.activate([
            headerTopConstraint,
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            positionLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -14),
            positionLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }

    func setupTasksContainer() {
        tasksContainer = NSView()
        tasksContainer.translatesAutoresizingMaskIntoConstraints = false
        tasksContainer.wantsLayer = true
        
        containerView.addSubview(tasksContainer)
        
        tasksContainerHeightConstraint = tasksContainer.heightAnchor.constraint(equalToConstant: rowHeight)
        
        NSLayoutConstraint.activate([
            tasksContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 4),
            tasksContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            tasksContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            tasksContainerHeightConstraint
        ])
    }

    func setupScrollIndicators() {
        let arrowConfig = NSImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        
        scrollUpIndicator = NSImageView()
        scrollUpIndicator.translatesAutoresizingMaskIntoConstraints = false
        scrollUpIndicator.image = NSImage(systemSymbolName: "chevron.up", accessibilityDescription: nil)?.withSymbolConfiguration(arrowConfig)
        scrollUpIndicator.contentTintColor = NSColor.tertiaryLabelColor
        scrollUpIndicator.alphaValue = 0.0
        
        scrollDownIndicator = NSImageView()
        scrollDownIndicator.translatesAutoresizingMaskIntoConstraints = false
        scrollDownIndicator.image = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil)?.withSymbolConfiguration(arrowConfig)
        scrollDownIndicator.contentTintColor = NSColor.tertiaryLabelColor
        scrollDownIndicator.alphaValue = 0.0
        
        containerView.addSubview(scrollUpIndicator)
        containerView.addSubview(scrollDownIndicator)
        
        NSLayoutConstraint.activate([
            scrollUpIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            scrollUpIndicator.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 6),
            scrollUpIndicator.widthAnchor.constraint(equalToConstant: 16),
            scrollUpIndicator.heightAnchor.constraint(equalToConstant: 10),
            
            scrollDownIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            scrollDownIndicator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10),
            scrollDownIndicator.widthAnchor.constraint(equalToConstant: 16),
            scrollDownIndicator.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    var previousActiveApp: NSRunningApplication?

    func rebuildUI() {
        guard isUIReady else { return }

        // Clear ALL subviews from tasksContainer, not just taskRows
        tasksContainer.subviews.forEach { $0.removeFromSuperview() }
        taskRows.removeAll()

        if tasks.isEmpty && !isShowingInput {
            showEmptyState()
            positionLabel.stringValue = "0/0"
        } else {
            buildTaskList()
            positionLabel.stringValue = "\(selectedIndex + 1)/\(tasks.count)"
        }

        updateScrollIndicators()
        resizePanel()
        saveData()
        rebuildMenu()
        updateStatusBarIcon()
    }

    func showEmptyState() {
        let emptyLabel = NSTextField(labelWithString: "Escribe para añadir una tarea")
        emptyLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        emptyLabel.textColor = .tertiaryLabelColor
        emptyLabel.alignment = .center
        emptyLabel.setAccessibilityLabel("Sin tareas")
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tasksContainer.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: tasksContainer.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: tasksContainer.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: tasksContainer.leadingAnchor),
            emptyLabel.trailingAnchor.constraint(equalTo: tasksContainer.trailingAnchor)
        ])
    }

    func buildTaskList() {
        let totalTasks = tasks.count
        let endIndex = min(scrollOffset + maxVisibleTasks, totalTasks)
        let actualVisibleCount = endIndex - scrollOffset
        
        guard actualVisibleCount > 0 else { return }
        
        var constraints: [NSLayoutConstraint] = []
        var lastRow: NSView?
        
        for i in 0..<actualVisibleCount {
            let taskIndex = scrollOffset + i
            let task = tasks[taskIndex]
            
            let row = EditableTaskRow(
                task: task,
                isSelected: taskIndex == selectedIndex,
                onEdit: { [weak self] newText, newPriority in
                    self?.updateTask(at: taskIndex, with: newText, priority: newPriority)
                },
                onStartEdit: { [weak self] in
                    self?.onRowStartedEditing(taskIndex)
                },
                onEndEdit: { [weak self] in
                    self?.onRowEndedEditing()
                }
            )
            row.translatesAutoresizingMaskIntoConstraints = false
            tasksContainer.addSubview(row)
            taskRows.append(row)
            
            constraints.append(contentsOf: [
                row.leadingAnchor.constraint(equalTo: tasksContainer.leadingAnchor),
                row.trailingAnchor.constraint(equalTo: tasksContainer.trailingAnchor),
                row.heightAnchor.constraint(equalToConstant: rowHeight)
            ])
            
            if let last = lastRow {
                constraints.append(row.topAnchor.constraint(equalTo: last.bottomAnchor, constant: 1))
                
                // Add subtle separator line between rows
                let separator = NSView()
                separator.translatesAutoresizingMaskIntoConstraints = false
                separator.wantsLayer = true
                separator.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.08).cgColor
                tasksContainer.addSubview(separator)
                
                constraints.append(contentsOf: [
                    separator.leadingAnchor.constraint(equalTo: tasksContainer.leadingAnchor, constant: 40),
                    separator.trailingAnchor.constraint(equalTo: tasksContainer.trailingAnchor, constant: -10),
                    separator.heightAnchor.constraint(equalToConstant: 0.5),
                    separator.bottomAnchor.constraint(equalTo: row.topAnchor, constant: 0.5)
                ])
            } else {
                constraints.append(row.topAnchor.constraint(equalTo: tasksContainer.topAnchor))
            }
            
            lastRow = row
        }
        
        if let last = lastRow {
            constraints.append(last.bottomAnchor.constraint(equalTo: tasksContainer.bottomAnchor))
        }
        
        NSLayoutConstraint.activate(constraints)
    }

    func updateScrollIndicators() {
        let hasMoreAbove = scrollOffset > 0
        let hasMoreBelow = scrollOffset + maxVisibleTasks < tasks.count
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            self.scrollUpIndicator.animator().alphaValue = hasMoreAbove ? 0.6 : 0.0
            self.scrollDownIndicator.animator().alphaValue = hasMoreBelow ? 0.6 : 0.0
        })
    }

    func ensureSelectedVisible() {
        if selectedIndex < scrollOffset {
            scrollOffset = selectedIndex
        } else if selectedIndex >= scrollOffset + maxVisibleTasks {
            scrollOffset = selectedIndex - maxVisibleTasks + 1
        }
        rebuildUI()
    }

    func resizePanel() {
        guard let topLeft = savedTopLeft else { return }
        isRepositioning = true

        let inputHeightIfVisible = isShowingInput ? inputHeight + 14 : 8
        let headerHeight: CGFloat = 22
        let bottomPadding: CGFloat = 20
        
        let visibleTaskCount: Int
        if tasks.isEmpty {
            visibleTaskCount = 1
        } else {
            visibleTaskCount = min(tasks.count - scrollOffset, maxVisibleTasks)
        }
        
        let tasksHeight = CGFloat(visibleTaskCount) * rowHeight + CGFloat(max(0, visibleTaskCount - 1)) * 2
        tasksContainerHeightConstraint.constant = max(tasksHeight, rowHeight)
        
        let totalHeight = inputHeightIfVisible + headerHeight + tasksHeight + bottomPadding

        let newOrigin = NSPoint(x: topLeft.x, y: topLeft.y - totalHeight)
        panel.setFrame(NSRect(x: newOrigin.x, y: newOrigin.y, width: panelWidth, height: totalHeight), display: true)
        containerView.frame = NSRect(x: 0, y: 0, width: panelWidth, height: totalHeight)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.isRepositioning = false
        }
    }

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateStatusBarIcon()
        rebuildMenu()
    }

    func updateStatusBarIcon() {
        guard let button = statusItem?.button else { return }
        
        let pendingCount = tasks.filter { !$0.isCompleted }.count
        
        if pendingCount > 0 {
            button.title = "\(pendingCount)"
            button.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        } else {
            button.title = ""
        }
        
        button.image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "Task Overlay")
        button.imagePosition = .imageLeft
    }

    func rebuildMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Mostrar  ⌃⇧Space", action: #selector(activateOverlay), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        if !tasks.isEmpty {
            for (index, task) in tasks.enumerated() {
                let prefix = index == selectedIndex ? "▶ " : "   "
                let checkmark = task.isCompleted ? "✓ " : "○ "
                let priorityIcon = task.priority == .high ? "🔴 " : task.priority == .medium ? "🟡 " : "🟢 "
                let item = NSMenuItem(title: "\(prefix)\(checkmark)\(priorityIcon)\(task.text)", action: #selector(selectFromMenu(_:)), keyEquivalent: "")
                item.tag = index
                menu.addItem(item)
            }
            menu.addItem(NSMenuItem.separator())
        }

        menu.addItem(NSMenuItem(title: "Salir", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc func selectFromMenu(_ sender: NSMenuItem) {
        selectedIndex = sender.tag
        ensureSelectedVisible()
        saveData()
    }

    func setupGlobalHotKey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (_, _, _) -> OSStatus in
            if let appDelegate = NSApp.delegate as? AppDelegate {
                DispatchQueue.main.async { appDelegate.activateOverlay() }
            }
            return noErr
        }, 1, &eventType, nil, nil)

        let modifiers: UInt32 = UInt32(controlKey | shiftKey)
        RegisterEventHotKey(49, modifiers, EventHotKeyID(signature: 0x544F5645, id: 1), GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasOption = modifiers.contains(.option)
        let hasCommand = modifiers.contains(.command)

        if isShowingInput {
            return
        }

        if taskRows.contains(where: { $0.isEditing }) {
            return
        }

        switch event.keyCode {
        case 126:
            if hasCommand {
                goToFirstTask()
            } else if hasOption {
                moveTaskUp()
            } else {
                moveUp()
            }
        case 125:
            if hasCommand {
                goToLastTask()
            } else if hasOption {
                moveTaskDown()
            } else {
                moveDown()
            }
        case 116:
            pageUp()
        case 121:
            pageDown()
        case 36:
            editSelectedTask()
        case 51:
            deleteSelectedTask()
        case 49:
            toggleTaskCompletion()
        case 53:
            hideOverlay()
        default:
            if let chars = event.characters, !chars.isEmpty {
                let validChars = CharacterSet.alphanumerics.union(.punctuationCharacters).union(.symbols)
                if chars.unicodeScalars.allSatisfy({ validChars.contains($0) }) {
                    showInputForNewTask(initialText: chars)
                }
            }
        }
    }

    func goToFirstTask() {
        guard !tasks.isEmpty else { return }
        selectedIndex = 0
        scrollOffset = 0
        rebuildUI()
    }

    func goToLastTask() {
        guard !tasks.isEmpty else { return }
        selectedIndex = tasks.count - 1
        scrollOffset = max(0, tasks.count - maxVisibleTasks)
        rebuildUI()
    }

    func pageUp() {
        guard !tasks.isEmpty else { return }
        selectedIndex = max(0, selectedIndex - maxVisibleTasks)
        scrollOffset = max(0, scrollOffset - maxVisibleTasks)
        rebuildUI()
    }

    func pageDown() {
        guard !tasks.isEmpty else { return }
        selectedIndex = min(tasks.count - 1, selectedIndex + maxVisibleTasks)
        if selectedIndex >= scrollOffset + maxVisibleTasks {
            scrollOffset = min(tasks.count - maxVisibleTasks, scrollOffset + maxVisibleTasks)
        }
        rebuildUI()
    }

    func moveUp() {
        guard !tasks.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + tasks.count) % tasks.count
        ensureSelectedVisible()
    }

    func moveDown() {
        guard !tasks.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % tasks.count
        ensureSelectedVisible()
    }

    func moveTaskUp() {
        guard selectedIndex > 0 else { return }
        tasks.swapAt(selectedIndex, selectedIndex - 1)
        selectedIndex -= 1
        ensureSelectedVisible()
    }

    func moveTaskDown() {
        guard selectedIndex < tasks.count - 1 else { return }
        tasks.swapAt(selectedIndex, selectedIndex + 1)
        selectedIndex += 1
        ensureSelectedVisible()
    }

    func editSelectedTask() {
        let rowIndex = selectedIndex - scrollOffset
        guard rowIndex >= 0 && rowIndex < taskRows.count else { return }
        taskRows[rowIndex].startEditing()
    }

    func deleteSelectedTask() {
        guard !tasks.isEmpty && selectedIndex < tasks.count else { return }
        tasks.remove(at: selectedIndex)
        if selectedIndex >= tasks.count { 
            selectedIndex = max(0, tasks.count - 1) 
        }
        ensureSelectedVisible()
    }

    func toggleTaskCompletion() {
        guard selectedIndex >= 0 && selectedIndex < tasks.count else { return }
        tasks[selectedIndex].isCompleted.toggle()
        rebuildUI()
    }

    func showInputForNewTask(initialText: String = "") {
        isShowingInput = true
        inputFieldHeightConstraint.constant = inputHeight
        headerTopConstraint.constant = inputHeight + 14
        inputContainer.alphaValue = 1.0
        inputField.stringValue = initialText
        resizePanel()
        panel.makeFirstResponder(inputField)
        inputField.currentEditor()?.moveToEndOfLine(nil)
    }

    func hideInput() {
        isShowingInput = false
        inputFieldHeightConstraint.constant = 0
        headerTopConstraint.constant = 8
        inputContainer.alphaValue = 0.0
        inputField.stringValue = ""
        resizePanel()
        panel.makeFirstResponder(containerView)
    }

    func submitNewTask() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let priority: TaskPriority
        if text.lowercased().hasPrefix("a ") {
            priority = .high
        } else if text.lowercased().hasPrefix("b ") {
            priority = .low
        } else {
            priority = .medium
        }
        
        var cleanText = text
        if text.lowercased().hasPrefix("a ") || text.lowercased().hasPrefix("m ") || text.lowercased().hasPrefix("b ") {
            cleanText = String(text.dropFirst(2))
        }
        
        if !cleanText.isEmpty {
            tasks.insert(TaskItem(text: cleanText, priority: priority), at: 0)
            selectedIndex = 0
            scrollOffset = 0
        }
        hideInput()
        rebuildUI()
    }

    func onRowStartedEditing(_ index: Int) {
        selectedIndex = index
        rebuildUI()
    }

    func onRowEndedEditing() {
        panel.makeFirstResponder(containerView)
    }

    func updateTask(at index: Int, with newText: String, priority: TaskPriority? = nil) {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            tasks.remove(at: index)
            if selectedIndex >= tasks.count { selectedIndex = max(0, tasks.count - 1) }
        } else {
            tasks[index].text = trimmed
            if let newPriority = priority {
                tasks[index].priority = newPriority
            }
        }
        rebuildUI()
    }

    @objc func activateOverlay() {
        // Save the currently active app before we steal focus
        previousActiveApp = NSWorkspace.shared.frontmostApplication
        
        isRepositioning = true

        if let topLeft = savedTopLeft {
            setTopLeft(topLeft)
        }

        panel.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()

        if let topLeft = savedTopLeft {
            setTopLeft(topLeft)
        }

        panel.makeFirstResponder(containerView)

        if tasks.isEmpty {
            showInputForNewTask()
        } else {
            if selectedIndex < 0 || selectedIndex >= tasks.count {
                selectedIndex = 0
            }
            ensureSelectedVisible()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isRepositioning = false
        }
    }

    func hideOverlay() {
        hideInput()
        taskRows.forEach { $0.endEditing() }
        panel.orderOut(nil)
        
        // Restore focus to the previous app
        if let previousApp = previousActiveApp {
            previousApp.activate(options: .activateIgnoringOtherApps)
        }
        previousActiveApp = nil
    }
}

extension AppDelegate: NSTextFieldDelegate {
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if control == inputField {
            if commandSelector == NSSelectorFromString("insertNewline:") {
                submitNewTask()
                return true
            } else if commandSelector == NSSelectorFromString("cancelOperation:") {
                hideInput()
                return true
            }
        }
        return false
    }
}

class EditableTaskRow: NSView, NSTextFieldDelegate {
    private let statusIcon: NSImageView
    private let priorityIndicator: NSView
    private let label: NSTextField
    private let editField: NSTextField
    private(set) var isEditing = false
    private var isSelected = false
    private var task: TaskItem

    var onEdit: (String, TaskPriority?) -> Void
    var onStartEdit: () -> Void
    var onEndEdit: () -> Void

    init(task: TaskItem, isSelected: Bool, onEdit: @escaping (String, TaskPriority?) -> Void, onStartEdit: @escaping () -> Void, onEndEdit: @escaping () -> Void) {
        self.task = task
        self.isSelected = isSelected
        self.onEdit = onEdit
        self.onStartEdit = onStartEdit
        self.onEndEdit = onEndEdit

        statusIcon = NSImageView()
        priorityIndicator = NSView()
        label = NSTextField(labelWithString: task.text)
        editField = NSTextField()

        super.init(frame: .zero)
        setupUI()
        updateAppearance()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 6

        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.imageScaling = .scaleProportionallyDown

        priorityIndicator.wantsLayer = true
        priorityIndicator.layer?.cornerRadius = 2.5
        priorityIndicator.translatesAutoresizingMaskIntoConstraints = false

        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false

        editField.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        editField.isBordered = false
        editField.backgroundColor = .clear
        editField.focusRingType = .none
        editField.isHidden = true
        editField.delegate = self
        editField.translatesAutoresizingMaskIntoConstraints = false

        addSubview(statusIcon)
        addSubview(priorityIndicator)
        addSubview(label)
        addSubview(editField)

        NSLayoutConstraint.activate([
            statusIcon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            statusIcon.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusIcon.widthAnchor.constraint(equalToConstant: 14),
            statusIcon.heightAnchor.constraint(equalToConstant: 14),

            priorityIndicator.leadingAnchor.constraint(equalTo: statusIcon.trailingAnchor, constant: 6),
            priorityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            priorityIndicator.widthAnchor.constraint(equalToConstant: 5),
            priorityIndicator.heightAnchor.constraint(equalToConstant: 5),

            label.leadingAnchor.constraint(equalTo: priorityIndicator.trailingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            editField.leadingAnchor.constraint(equalTo: priorityIndicator.trailingAnchor, constant: 8),
            editField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            editField.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(clickGesture)
        
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        updateAccessibilityLabel()
    }

    @objc private func handleClick() {
        if !isEditing {
            startEditing()
        }
    }

    private func updateAccessibilityLabel() {
        let status = task.isCompleted ? "completada" : "pendiente"
        let priority = task.priority == .high ? "alta prioridad" : task.priority == .medium ? "prioridad media" : "baja prioridad"
        setAccessibilityLabel("\(task.text), \(status), \(priority)")
    }

    func setSelected(_ selected: Bool) {
        isSelected = selected
        updateAppearance()
    }

    func startEditing() {
        isEditing = true
        editField.stringValue = task.text
        label.isHidden = true
        editField.isHidden = false
        onStartEdit()
        window?.makeFirstResponder(editField)
        editField.selectText(nil)
        updateAppearance()
    }

    func endEditing() {
        guard isEditing else { return }
        isEditing = false
        label.isHidden = false
        editField.isHidden = true
        onEndEdit()
        updateAppearance()
    }

    private func updateAppearance() {
        let imageName = task.isCompleted ? "checkmark.circle.fill" : "circle"
        let imageColor = task.isCompleted ? NSColor.systemGreen : NSColor.tertiaryLabelColor
        statusIcon.image = NSImage(systemSymbolName: imageName, accessibilityDescription: nil)
        statusIcon.contentTintColor = imageColor

        let priorityColor: NSColor
        switch task.priority {
        case .high:
            priorityColor = .systemRed
        case .medium:
            priorityColor = .systemOrange
        case .low:
            priorityColor = .systemGreen
        }
        priorityIndicator.layer?.backgroundColor = priorityColor.cgColor

        if task.isCompleted {
            let attributedString = NSMutableAttributedString(string: task.text)
            attributedString.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: task.text.count))
            attributedString.addAttribute(.foregroundColor, value: NSColor.tertiaryLabelColor, range: NSRange(location: 0, length: task.text.count))
            label.attributedStringValue = attributedString
        } else {
            label.stringValue = task.text
            label.textColor = isSelected ? .labelColor : .secondaryLabelColor
        }

        if isEditing {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.25).cgColor
        } else if isSelected {
            layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.15).cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
        }

        updateAccessibilityLabel()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == NSSelectorFromString("insertNewline:") {
            let newText = editField.stringValue
            task.text = newText
            endEditing()
            onEdit(newText, task.priority)
            return true
        } else if commandSelector == NSSelectorFromString("cancelOperation:") {
            endEditing()
            return true
        }
        return false
    }
}

class TaskContainerView: NSVisualEffectView {
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if let panel = window as? KeyablePanel {
            panel.keyHandler?(event)
        }
    }
}

class KeyablePanel: NSPanel {
    var keyHandler: ((NSEvent) -> Void)?

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        keyHandler?(event)
    }
}
