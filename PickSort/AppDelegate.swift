//
//  AppDelegate.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 19/07/25.
//

import Cocoa

// MARK: - Communication Protocol
// Updated protocol for more complex communication.
protocol ControlsViewControllerDelegate: AnyObject {
    // Tells the delegate a directory was chosen.
    func controlsViewController(_ controller: ControlsViewController, didSelectDirectoryWith imageURLs: [URL])
    
    // Asks the delegate for the currently displayed image's URL.
    func currentImageURL(for controller: ControlsViewController) -> URL?
    
    // Asks the delegate for the tags associated with a specific URL.
    func tags(for controller: ControlsViewController, url: URL) -> [String]
    
    // Tells the delegate that the tags for a URL have been updated.
    func controlsViewController(_ controller: ControlsViewController, didUpdateTags newTags: [String], for url: URL)
}


// MARK: - AppDelegate (Application Entry Point)
class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: NSWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let imageVC = ImageViewController()
        let controlsVC = ControlsViewController()

        // --- DELEGATE & REFERENCE SETUP ---
        // Set up the two-way communication channel.
        controlsVC.delegate = imageVC
        imageVC.controlsVC = controlsVC // Give ImageVC a reference to ControlsVC
        
        let splitVC = NSSplitViewController()
        let imageItem = NSSplitViewItem(viewController: imageVC)
        let controlsItem = NSSplitViewItem(viewController: controlsVC)
        
        imageItem.holdingPriority = .defaultLow + 1
        controlsItem.holdingPriority = .defaultLow

        splitVC.addSplitViewItem(imageItem)
        splitVC.addSplitViewItem(controlsItem)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.miniaturizable, .closable, .resizable, .titled],
            backing: .buffered,
            defer: false)
        window.center()
        window.title = "Image Tagger"
        window.contentViewController = splitVC

        let wc = NSWindowController(window: window)
        wc.showWindow(self)
        self.windowController = wc
    }
}

// MARK: - ImageViewController (Left Pane)
class ImageViewController: NSViewController {

    // --- Data Source ---
    private var imageURLs: [URL] = []
    private var currentIndex: Int = 0
    private var imageTags: [URL: [String]] = [:] // Source of truth for tags
    
    // --- Reference to ControlsVC for UI updates ---
    weak var controlsVC: ControlsViewController?

    // --- UI Elements ---
    private let imageView: NSImageView = {
        let iv = NSImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.imageScaling = .scaleProportionallyDown
        iv.image = NSImage(named: NSImage.iconViewTemplateName)
        iv.wantsLayer = true
        iv.layer?.backgroundColor = NSColor(white: 0.1, alpha: 1.0).cgColor
        iv.layer?.cornerRadius = 10
        iv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return iv
    }()
    
    private lazy var previousButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.goBackTemplateName)!, target: self, action: #selector(navigateImage))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.tag = -1
        return button
    }()
    
    private lazy var nextButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.goForwardTemplateName)!, target: self, action: #selector(navigateImage))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.tag = 1
        return button
    }()
    
    private let imageNameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "No Image")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.textColor = .secondaryLabelColor
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadTags()
        setupUI()
        updateUIForCurrentState()
    }
    
    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(previousButton)
        view.addSubview(nextButton)
        view.addSubview(imageNameLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            imageNameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            imageNameLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            imageNameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageNameLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -80),
            previousButton.centerYAnchor.constraint(equalTo: imageNameLabel.centerYAnchor),
            previousButton.trailingAnchor.constraint(equalTo: imageNameLabel.leadingAnchor, constant: -8),
            nextButton.centerYAnchor.constraint(equalTo: imageNameLabel.centerYAnchor),
            nextButton.leadingAnchor.constraint(equalTo: imageNameLabel.trailingAnchor, constant: 8),
        ])
    }
    
    private func updateUIForCurrentState() {
        guard !imageURLs.isEmpty else {
            imageView.image = NSImage(named: NSImage.iconViewTemplateName)
            imageNameLabel.stringValue = "No Images Found"
            previousButton.isEnabled = false
            nextButton.isEnabled = false
            controlsVC?.updateTagDisplay() // Tell controls to update
            return
        }
        
        imageView.image = NSImage(contentsOf: imageURLs[currentIndex])
        imageNameLabel.stringValue = imageURLs[currentIndex].lastPathComponent
        previousButton.isEnabled = currentIndex > 0
        nextButton.isEnabled = currentIndex < imageURLs.count - 1
        
        // After updating self, tell the controls pane to update its tag display
        controlsVC?.updateTagDisplay()
    }
    
    @objc private func navigateImage(_ sender: NSButton) {
        let newIndex = currentIndex + sender.tag
        if newIndex >= 0 && newIndex < imageURLs.count {
            currentIndex = newIndex
            updateUIForCurrentState()
        }
    }
    
    // --- Tag Persistence ---
    private let imageTagsKey = "imageTagsKey"
    
    private func saveTags() {
        // We need to convert [URL: [String]] to [String: [String]] for property list serialization.
        let stringKeyedTags = Dictionary(uniqueKeysWithValues: imageTags.map { (url, tags) in (url.absoluteString, tags) })
        UserDefaults.standard.set(stringKeyedTags, forKey: imageTagsKey)
    }
    
    private func loadTags() {
        guard let stringKeyedTags = UserDefaults.standard.dictionary(forKey: imageTagsKey) as? [String: [String]] else { return }
        // Convert back to [URL: [String]]
        self.imageTags = Dictionary(uniqueKeysWithValues: stringKeyedTags.compactMap { (key, tags) in
            guard let url = URL(string: key) else { return nil }
            return (url, tags)
        })
    }
}

// MARK: - Delegate Conformance
extension ImageViewController: ControlsViewControllerDelegate {
    func controlsViewController(_ controller: ControlsViewController, didSelectDirectoryWith imageURLs: [URL]) {
        self.imageURLs = imageURLs
        self.currentIndex = 0
        updateUIForCurrentState()
    }
    
    func currentImageURL(for controller: ControlsViewController) -> URL? {
        guard !imageURLs.isEmpty && currentIndex < imageURLs.count else { return nil }
        return imageURLs[currentIndex]
    }
    
    func tags(for controller: ControlsViewController, url: URL) -> [String] {
        return imageTags[url] ?? []
    }
    
    func controlsViewController(_ controller: ControlsViewController, didUpdateTags newTags: [String], for url: URL) {
        imageTags[url] = newTags
        saveTags() // Persist changes
    }
}


// MARK: - ControlsViewController (Right Pane)
class ControlsViewController: NSViewController {

    weak var delegate: ControlsViewControllerDelegate?

    // --- UPDATED UI Elements for Tagging ---
    private let currentTagsTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Current Tags:")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let currentTagsDisplayLabel: NSTextField = {
        let label = NSTextField(labelWithString: "None")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var predefinedTagSelector: NSPopUpButton = {
        let popUp = NSPopUpButton(frame: .zero)
        popUp.translatesAutoresizingMaskIntoConstraints = false
        popUp.addItems(withTitles: ["jawa", "padang", "sunda"])
        return popUp
    }()
    
    private lazy var addTagButton: NSButton = {
        let button = NSButton(title: "Add Tag", target: self, action: #selector(addTagTapped))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        return button
    }()
    
    // --- Original UI Elements ---
    private let directoryLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Directory: (None Selected)")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingHead
        return label
    }()
    
    private lazy var selectDirectoryButton: NSButton = {
        let button = NSButton(title: "Select...", target: self, action: #selector(selectDirectoryClicked))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        restoreSavedDirectory()
    }
    
    private func setupUI() {
        // Add all subviews
        [directoryLabel, selectDirectoryButton, currentTagsTitleLabel, currentTagsDisplayLabel, predefinedTagSelector, addTagButton].forEach(view.addSubview)
        
        NSLayoutConstraint.activate([
            // Directory Selector
            selectDirectoryButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            selectDirectoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            directoryLabel.centerYAnchor.constraint(equalTo: selectDirectoryButton.centerYAnchor),
            directoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            directoryLabel.trailingAnchor.constraint(equalTo: selectDirectoryButton.leadingAnchor, constant: -8),
            
            // Current Tags Display
            currentTagsTitleLabel.topAnchor.constraint(equalTo: directoryLabel.bottomAnchor, constant: 30),
            currentTagsTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            currentTagsDisplayLabel.topAnchor.constraint(equalTo: currentTagsTitleLabel.bottomAnchor, constant: 8),
            currentTagsDisplayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentTagsDisplayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // New Tag Input (using the popup button)
            predefinedTagSelector.topAnchor.constraint(equalTo: currentTagsDisplayLabel.bottomAnchor, constant: 20),
            predefinedTagSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            addTagButton.leadingAnchor.constraint(equalTo: predefinedTagSelector.trailingAnchor, constant: 8),
            addTagButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTagButton.centerYAnchor.constraint(equalTo: predefinedTagSelector.centerYAnchor),
            addTagButton.widthAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    @objc private func addTagTapped() {
        guard let url = delegate?.currentImageURL(for: self) else {
            print("No image selected to tag.")
            return
        }
        
        // Get the selected tag from the popup button
        guard let newTag = predefinedTagSelector.titleOfSelectedItem else {
            print("No tag selected from dropdown.")
            return
        }
        
        var currentTags = delegate?.tags(for: self, url: url) ?? []
        
        guard currentTags.count < 32 else {
            print("Maximum of 32 tags reached for this image.")
            return // Enforce the limit
        }
        
        if !currentTags.contains(newTag) {
            currentTags.append(newTag)
            delegate?.controlsViewController(self, didUpdateTags: currentTags, for: url)
            updateTagDisplay() // Refresh the UI
        } else {
            print("Tag '\(newTag)' already exists for this image.")
        }
    }
    
    /// Public method called by ImageViewController to refresh the tag display.
    func updateTagDisplay() {
        guard let url = delegate?.currentImageURL(for: self) else {
            currentTagsDisplayLabel.stringValue = "No image selected."
            setTaggingUI(enabled: false)
            return
        }
        
        let tags = delegate?.tags(for: self, url: url) ?? []
        if tags.isEmpty {
            currentTagsDisplayLabel.stringValue = "None"
        } else {
            currentTagsDisplayLabel.stringValue = tags.joined(separator: ", ")
        }
        setTaggingUI(enabled: true)
    }
    
    private func setTaggingUI(enabled: Bool) {
        predefinedTagSelector.isEnabled = enabled
        addTagButton.isEnabled = enabled
    }
    
    // --- Original Methods (Unchanged) ---
    @objc private func selectDirectoryClicked() {
        let openPanel = NSOpenPanel()
        openPanel.message = "Please select a directory"
        openPanel.prompt = "Select"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            updateDirectoryLabel(with: url)
            saveDirectoryPermission(for: url)
            scanDirectoryAndInformDelegate(at: url)
        }
    }
    
    private func updateDirectoryLabel(with url: URL) {
        directoryLabel.stringValue = "Directory: \(url.lastPathComponent)"
        directoryLabel.toolTip = url.path
    }
    
    private func scanDirectoryAndInformDelegate(at url: URL) {
        let validExtensions = ["jpg", "jpeg", "png", "heic", "gif", "tiff"]
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: .skipsHiddenFiles)
            let imageURLs = contents.filter { validExtensions.contains($0.pathExtension.lowercased()) }
            delegate?.controlsViewController(self, didSelectDirectoryWith: imageURLs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }))
        } catch {
            print("Error scanning directory: \(error)")
        }
    }
    
    private let directoryBookmarkKey = "directoryBookmarkKey"
    
    private func saveDirectoryPermission(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: directoryBookmarkKey)
        } catch {
            print("Error saving directory bookmark: \(error)")
        }
    }
    
    private func restoreSavedDirectory() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: directoryBookmarkKey) else { return }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale { saveDirectoryPermission(for: url) }
            
            if url.startAccessingSecurityScopedResource() {
                DispatchQueue.main.async {
                    self.updateDirectoryLabel(with: url)
                    self.scanDirectoryAndInformDelegate(at: url)
                }
            }
        } catch {
            print("Error restoring directory bookmark: \(error)")
        }
    }
}
