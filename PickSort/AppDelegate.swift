//
//  AppDelegate.swift
//  PickSort
//
//  Created by Ashraf Alif Adillah on 19/07/25.
//

import Cocoa

// MARK: - Communication Protocol
// This protocol allows the ControlsViewController to send data (the list of image URLs)
// back to its delegate (which will be the ImageViewController).
protocol ControlsViewControllerDelegate: AnyObject {
    func controlsViewController(_ controller: ControlsViewController, didSelectDirectoryWith imageURLs: [URL])
}


// MARK: - AppDelegate (Application Entry Point)
class AppDelegate: NSObject, NSApplicationDelegate {

    private var windowController: NSWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        let imageVC = ImageViewController()
        let controlsVC = ControlsViewController()

        // --- DELEGATE SETUP ---
        // This is the crucial step that connects the two controllers.
        controlsVC.delegate = imageVC
        
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

    // --- UI Elements ---
    private let imageView: NSImageView = {
        let iv = NSImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.imageScaling = .scaleProportionallyDown // Use this to prevent upscaling pixelation
        iv.image = NSImage(named: NSImage.iconViewTemplateName)
        iv.wantsLayer = true
        iv.layer?.backgroundColor = NSColor(white: 0.1, alpha: 1.0).cgColor
        iv.layer?.cornerRadius = 10
        
        // Lower the image view's resistance to being compressed.
        // This tells the layout system that it's okay to shrink the image view
        // smaller than its intrinsic content size. The default is 750.
        iv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iv.setContentCompressionResistancePriority(.defaultLow, for: .vertical) // <-- THE NEW FIX IS HERE
        
        return iv
    }()
    
    private lazy var previousButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.goBackTemplateName)!, target: self, action: #selector(navigateImage))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.tag = -1 // Use tag to signify direction
        return button
    }()
    
    private lazy var nextButton: NSButton = {
        let button = NSButton(image: NSImage(named: NSImage.goForwardTemplateName)!, target: self, action: #selector(navigateImage))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isBordered = false
        button.tag = 1 // Use tag to signify direction
        return button
    }()
    
    private let imageNameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "No Image")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.textColor = .secondaryLabelColor
        return label
    }()

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUIForCurrentState()
    }
    
    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(previousButton)
        view.addSubview(nextButton)
        view.addSubview(imageNameLabel)
        
        NSLayoutConstraint.activate([
            // Image View constraints (leaving space at the bottom)
            imageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            
            // Navigation controls constraints (positioned below the image view)
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
            return
        }
        
        // Update image
        imageView.image = NSImage(contentsOf: imageURLs[currentIndex])
        
        // Update label
        imageNameLabel.stringValue = imageURLs[currentIndex].lastPathComponent
        
        // Update buttons
        previousButton.isEnabled = currentIndex > 0
        nextButton.isEnabled = currentIndex < imageURLs.count - 1
    }
    
    @objc private func navigateImage(_ sender: NSButton) {
        let newIndex = currentIndex + sender.tag
        if newIndex >= 0 && newIndex < imageURLs.count {
            currentIndex = newIndex
            updateUIForCurrentState()
        }
    }
}

// MARK: - Delegate Conformance
extension ImageViewController: ControlsViewControllerDelegate {
    func controlsViewController(_ controller: ControlsViewController, didSelectDirectoryWith imageURLs: [URL]) {
        self.imageURLs = imageURLs
        self.currentIndex = 0
        updateUIForCurrentState()
    }
}


// MARK: - ControlsViewController (Right Pane)
class ControlsViewController: NSViewController {

    // --- Delegate Property ---
    weak var delegate: ControlsViewControllerDelegate?

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
    
    private let tagLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Tag:")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tagSelector: NSPopUpButton = {
        let popUp = NSPopUpButton(title: "like", target: self, action: #selector(tagDidChange))
        popUp.translatesAutoresizingMaskIntoConstraints = false
        return popUp
    }()

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureTagSelector()
        restoreSavedDirectory()
    }
    
    private func setupUI() {
        view.addSubview(directoryLabel)
        view.addSubview(selectDirectoryButton)
        view.addSubview(tagLabel)
        view.addSubview(tagSelector)
        
        NSLayoutConstraint.activate([
            selectDirectoryButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            selectDirectoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            directoryLabel.centerYAnchor.constraint(equalTo: selectDirectoryButton.centerYAnchor),
            directoryLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            directoryLabel.trailingAnchor.constraint(equalTo: selectDirectoryButton.leadingAnchor, constant: -8),
            tagLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tagLabel.topAnchor.constraint(equalTo: directoryLabel.bottomAnchor, constant: 30),
            tagSelector.centerYAnchor.constraint(equalTo: tagLabel.centerYAnchor),
            tagSelector.leadingAnchor.constraint(equalTo: tagLabel.trailingAnchor, constant: 8),
            tagSelector.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func configureTagSelector() {
        tagSelector.removeAllItems()
        tagSelector.addItems(withTitles: ["like", "love", "lust"])
    }
    
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
    
    @objc private func tagDidChange() {
        if let selectedTag = tagSelector.titleOfSelectedItem {
            print("Selected tag is now: \(selectedTag)")
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
