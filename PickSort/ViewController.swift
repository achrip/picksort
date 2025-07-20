//
//  ViewController.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 19/07/25.
//

import Cocoa

class ViewController: NSViewController {
    private let greetingLabel: NSTextField = {
        let textfield = NSTextField(labelWithString: "Hello, PickSort User!")
        textfield.font = NSFont.systemFont(ofSize: 20, weight: .medium)
        textfield.textColor = .labelColor

        // THIS IS THE MOST IMPORTANT LINE FOR PROGRAMMATIC AUTOLAYOUT
        // Gemini
        textfield.translatesAutoresizingMaskIntoConstraints = false

        return textfield
    }()

    private let actionButton: NSButton = {
        let button = NSButton(title: "Click Me!", target: nil, action: nil)
        button.bezelStyle = .rounded

        button.translatesAutoresizingMaskIntoConstraints = false

        return button
    }()

    // Method for creating the view hierarchy
    override func loadView() {
        // Controller has to provide a view, and they do that here.
        self.view = NSView()
        self.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
    }

    // Method for adding subviews and constraints
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HERE")

        view.addSubview(greetingLabel)
        view.addSubview(actionButton)

        NSLayoutConstraint.activate([
            greetingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            greetingLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 32),
        ])
    }
}

class MainViewController: NSViewController {

    // MARK: - UI Elements

    private let sourceLabel: NSTextField = {
        let textField = NSTextField(labelWithString: "Source Directory: (Not Selected)")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textField.lineBreakMode = .byTruncatingHead
        return textField
    }()

    private lazy var selectSourceButton: NSButton = {
        let button = NSButton(title: "Select Source...", target: self, action: #selector(selectDirectoryClicked))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        button.tag = 0 // Use a tag to identify the button
        return button
    }()

    private let destinationLabel: NSTextField = {
        let textField = NSTextField(labelWithString: "Destination Directory: (Not Selected)")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textField.lineBreakMode = .byTruncatingHead
        return textField
    }()

    private lazy var selectDestinationButton: NSButton = {
        let button = NSButton(title: "Select Destination...", target: self, action: #selector(selectDirectoryClicked))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        button.tag = 1 // Use a different tag
        return button
    }()

    // MARK: - View Lifecycle

    override func loadView() {
        self.view = NSView()
        self.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        restoreSavedPermissions()
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.addSubview(sourceLabel)
        view.addSubview(selectSourceButton)
        view.addSubview(destinationLabel)
        view.addSubview(selectDestinationButton)

        NSLayoutConstraint.activate([
            // Source UI elements
            selectSourceButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            selectSourceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            sourceLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sourceLabel.trailingAnchor.constraint(equalTo: selectSourceButton.leadingAnchor, constant: -10),
            sourceLabel.centerYAnchor.constraint(equalTo: selectSourceButton.centerYAnchor),

            // Destination UI elements
            selectDestinationButton.topAnchor.constraint(equalTo: selectSourceButton.bottomAnchor, constant: 20),
            selectDestinationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            destinationLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            destinationLabel.trailingAnchor.constraint(equalTo: selectDestinationButton.leadingAnchor, constant: -10),
            destinationLabel.centerYAnchor.constraint(equalTo: selectDestinationButton.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func selectDirectoryClicked(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.message = "Please select a directory"
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        // Run the panel and handle the result
        if openPanel.runModal() == .OK {
            guard let url = openPanel.url else { return }
            
            // Save permission for this URL and update the UI
            savePermission(for: url, withKey: (sender.tag == 0) ? "sourceURLBookmark" : "destinationURLBookmark")
            updateLabel(for: url, withTag: sender.tag)
        }
    }
    
    // MARK: - Permission Handling (Security-Scoped Bookmarks)

    /// Saves a security-scoped bookmark for the given URL to UserDefaults.
    private func savePermission(for url: URL, withKey key: String) {
        do {
            // Create bookmark data with security scope.
            // This allows us to access the URL again after the app relaunches.
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: key)
            print("Successfully saved bookmark for \(key)")
        } catch {
            print("Error saving bookmark: \(error.localizedDescription)")
        }
    }

    /// Tries to restore access to previously selected directories on app launch.
    private func restoreSavedPermissions() {
        restoreAccess(forKey: "sourceURLBookmark", withTag: 0)
        restoreAccess(forKey: "destinationURLBookmark", withTag: 1)
    }
    
    /// Restores access from a bookmark stored in UserDefaults.
    private func restoreAccess(forKey key: String, withTag tag: Int) {
        guard let bookmarkData = UserDefaults.standard.data(forKey: key) else { return }
        
        do {
            var isStale = false
            // Resolve the bookmark data back into a URL.
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            
            if isStale {
                // The bookmark is old and needs to be saved again.
                // This can happen if the file was moved.
                print("Bookmark for \(key) is stale. Re-saving.")
                savePermission(for: url, withKey: key)
            }
            
            // Start accessing the security-scoped resource.
            if url.startAccessingSecurityScopedResource() {
                print("Successfully started accessing \(key)")
                updateLabel(for: url, withTag: tag)
                // Note: You should call `stopAccessingSecurityScopedResource()` when you are done with the file access.
                // For an app where you might access it anytime, you might manage this differently.
            }
        } catch {
            print("Error restoring bookmark: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UI Updates
    
    private func updateLabel(for url: URL, withTag tag: Int) {
        let label = (tag == 0) ? sourceLabel : destinationLabel
        let prefix = (tag == 0) ? "Source" : "Destination"
        label.stringValue = "\(prefix) Directory: \(url.lastPathComponent)"
        label.toolTip = url.path // Show full path on hover
    }
}
