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

    // --- NEW: Data source for the searchable tags ---
    private let allTags: [String] = [
        "Abim Mayu Indra Ardiansah", "Abimanyu Damarjati", "Adeline Charlotte Augustinne", "Adhis Helsa Aurellia", "Adinda Meutia Rizkina",
        "Adrian Alfajri", "Adrian Hananto", "Adya Muhammad Prawira", "Ageng Tawang Aryonindito", "Agung M Syukra Al Muzakir",
        "Ahmad Al Wabil", "Ahmed Nizhan Haikal", "Ailsa Anarghia Rachman", "Aissya Jelitawati", "Akbar Febri W A",
        "Aldrian Raffi Wicaksono", "Ali Jazzy Rasyid", "Alifa Reppawali", "Alvin Justine", "Alya Salsabila Haritsian",
        "Amelia Morencia Irena", "Ammar Sufyan", "Andrea Octaviani", "Angel Augustine Cheyla", "Angeline Rachel",
        "Anisa Amalia Putri", "Annisya Dwi Fitry", "Aretha Natalova Wahyudi", "Arief Roihan Nur Rahman", "Arin Juan Sari",
        "Aristo Yongka", "Arya Maulana Bratajaya Akmal", "Ashraf Alif Adillah", "Atilla Rizkyara", "Aulia Nisrina Rosanita",
        "Aurelly Joeandani", "Azalia Amanda Putri Sampurno", "Benedictus Yogatama Favian Satyajati", "Brayen Fredgin Cahyadi",
        "Bryan Bramaskara", "Calista Abigail Wairata", "Callista Althea Hartanto", "Callista Andreane", "Camilla Tiara Dewi",
        "Chairal Octavyanz Tanjung", "Chandra Rudy Saputra", "Channo Adikara", "Chavia Viriela Budianto", "Chikmah",
        "Christian Luis Efendy", "Ciko Edo Febrian", "Claurent Virginie Surya", "Crescentia Karen Prasetya", "Cynthia Shabrina",
        "Daven Karim", "Destu Cikal Ramdani", "Devina Sepfia Rizal", "Dicky Dharma Susanto", "Dwitya Amanda Ayuningtias",
        "Elia Karoeniadi", "Elisabeth Levana Thedjakusuma", "Eliza Vornia", "Emmanuel Rieno Bobba Pratama", "Esthervany Anrika",
        "Ethelind Septiani Metta", "Evan Lokajaya", "Evelyn Wijaya", "Fa'izah Fida Afifah", "Fachry Anwar Hamsyana",
        "Farida Noorseptiyanti", "Farrah Allysha Maharani", "Feby Agatha Christie Kurniawan", "Felda Everyl", "Felicia Rachell Korich",
        "Ferdinand Lunardy", "Flavia Angelina Witarsah", "Francesco Emmanuel Setiawan", "Franco Antonio Pranata", "Frengky Gunawan",
        "Frewin Saputra Sidabariba", "Gabriel Christopher Tanod", "Gede Binar Kukuh Widanda", "George Timothy Mars", "Georgius Kenny Gunawan",
        "Gibran Shevaldo", "Gladys Lionardi", "Grace Maria Yosephine Agustin Gultom", "Grachia Uliari Magdalena Purba", "Griselda Shavilla",
        "Gustavo Hoze Ercolesea", "Hafizhuddin Hanif", "Hans Cahya Buana", "Hany Wijaya", "Hendrik Nicolas Carlo",
        "Ikhsan Dhaffa Nugraha", "Ilham Hadi Shahputra", "Ivan Setiawan", "Jehoiada Wong", "Jessica", "Jessica Lynn Wibowo",
        "Jesslyn Amanda Mulyawan", "Johansen Marlee", "Jonathan Calvin Sutrisna", "Jonathan Tjahjadi", "Jordan Josdaan",
        "Joreinhard Rotuah Munandar", "Jose Andreas Lie", "Josephine Michelle Kho", "Kelvin Alexander Bong", "Kelvin Ongko Hakim",
        "Kenneth Mayer Wijaya", "Kevin Priatna", "Khresna Sariyanto", "Lin Dan Christiano", "Louis Oktovianus", "Louise Fernando",
        "Lysandra Velyca", "Maharani Aulia Syifa", "Marcelinus Gerardo Ari N", "Marshia Haunafi", "Michelle Pandojo Lukman",
        "Miftah Fauzy", "Mirabella", "Mochammad Dimas Editiya", "Muchamad Iqbal Fauzi", "Muh Irhamdi Fahdiyan Noor",
        "Muhammad Al Amin Dwiesta", "Muhammad Ardiansyah Asrifah", "Muhammad Ariq Hendry", "Muhammad Asaduddin", "Muhammad Azmi",
        "Muhammad Fathur Hidayat", "Muhammad Fatih Daffa Fawwaz", "Muhammad Hafizh", "Muhammad Hamzah Robbani", "Muhammad Hannan Massimo Madjid",
        "Muhammad Keinanthan Wahyuwardhana", "Muhammad Khadafie Satya Sudarto", "Muhammad Rifqi Rahman", "Muhammad Umar Abdul Azis",
        "Mutakin", "Natasha Charissa Sidharta", "Natasya Felicia Malonda", "Nicholas Tristandi", "Nicholas Vincent Chao",
        "Nur Fajar Sayyidul Ayyam", "Oxa Marvel Ilman Thaariq", "Patricia Putri Art Syani", "Priscilla Anthonio Kurniawan",
        "Rais Zainuri", "Raissa Ravelina", "Raphael Gregorius Hakim", "Rastya Widya Hapsari", "Regina Celine Adiwinata",
        "Reinhart Christopher", "Reymunda Dwi Alfathur", "Reynaldo Marchell Bagas Adji", "Reynard Hansel", "Richard Sugiharto",
        "Richard Wijaya Harianto", "Rico Tandrio", "Rif'an Amrozi", "Sabri Ramadhani", "Salsabiila Bazaluna Febriadini",
        "Samuel Dwiputra Tjan", "Satria Dafa Putra Wardhana", "Sessario Ammar Wibowo", "Shawn Andrew", "Shierly Anastasya Lie",
        "Sieka Puspa Mawary", "Silvester Justine Cahyono", "Stanislaus Kanaya Jerry Febriano", "Stephen Hau", "SUFI ARIFIN",
        "Syaoki Biek", "Teuku Fazariz Basya", "Thania Natasha", "Theodora Stefani Handojo", "Thingkilia Finnatia Husin",
        "Tiara Aurelia Putri", "Timothy Elisa Putra", "Tm Revanza Narendra Pradipta", "Tomi Timutius", "Valencia Sutanto",
        "Valentinus", "Vanessa Audreylia", "Vania Carissa", "Vianna Calista Tamsil", "Victor Chandra", "Vincent Wisnata",
        "Vira Fitriyani", "William", "Wiwi Oktriani", "Yehezkiel Joseph Widianto", "Yohanes Valentino Stanley",
        "Yonathan Handoyo", "Yonathan Hilkia", "Zaidan Akmal Rabbani", "Zakia Noorardini", "Zikar Nurizky"
    ]
    private var filteredTags: [String] = []

    // --- UPDATED UI Elements for Tagging ---
    private let currentTagsTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Tag Saat Ini:")
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let currentTagsDisplayLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Tidak ada")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private lazy var tagComboBox: NSComboBox = {
        let comboBox = NSComboBox()
        comboBox.translatesAutoresizingMaskIntoConstraints = false
        comboBox.usesDataSource = true // We will provide the data
        comboBox.placeholderString = "Cari atau pilih nama"
        return comboBox
    }()
    
    private lazy var addTagButton: NSButton = {
        let button = NSButton(title: "Tambah Tag", target: self, action: #selector(addTagTapped))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        return button
    }()
    
    // --- NEW: Remove Tag Button ---
    private lazy var removeLastTagButton: NSButton = {
        let button = NSButton(title: "Hapus Terakhir", target: self, action: #selector(removeLastTagTapped))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        return button
    }()
    
    // --- Original UI Elements ---
    private let directoryLabel: NSTextField = {
        let label = NSTextField(labelWithString: "Direktori: (Belum Dipilih)")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byTruncatingHead
        return label
    }()
    
    private lazy var selectDirectoryButton: NSButton = {
        let button = NSButton(title: "Pilih...", target: self, action: #selector(selectDirectoryClicked))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .rounded
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        filteredTags = allTags
        setupUI()
        setupComboBox()
        restoreSavedDirectory()
    }
    
    private func setupUI() {
        // Add all subviews
        [directoryLabel, selectDirectoryButton, currentTagsTitleLabel, currentTagsDisplayLabel, tagComboBox, addTagButton, removeLastTagButton].forEach(view.addSubview)
        
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
            
            // New Tag Input (using the combo box)
            tagComboBox.topAnchor.constraint(equalTo: currentTagsDisplayLabel.bottomAnchor, constant: 20),
            tagComboBox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tagComboBox.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            // Tag Action Buttons
            addTagButton.topAnchor.constraint(equalTo: tagComboBox.bottomAnchor, constant: 8),
            addTagButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            removeLastTagButton.centerYAnchor.constraint(equalTo: addTagButton.centerYAnchor),
            removeLastTagButton.trailingAnchor.constraint(equalTo: addTagButton.leadingAnchor, constant: -8)
        ])
    }
    
    private func setupComboBox() {
        tagComboBox.dataSource = self
        tagComboBox.delegate = self
    }
    
    @objc private func addTagTapped() {
        guard let url = delegate?.currentImageURL(for: self) else {
            print("No image selected to tag.")
            return
        }
        
        let newTag = tagComboBox.stringValue
        
        guard allTags.contains(newTag) else {
            print("Invalid tag: '\(newTag)'. Please select a name from the list.")
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
            updateTagDisplay()
            tagComboBox.stringValue = ""
            filteredTags = allTags
            tagComboBox.reloadData()
        } else {
            print("Tag '\(newTag)' already exists for this image.")
        }
    }
    
    // --- NEW: Action for Remove Button ---
    @objc private func removeLastTagTapped() {
        guard let url = delegate?.currentImageURL(for: self) else { return }
        
        var currentTags = delegate?.tags(for: self, url: url) ?? []
        
        if !currentTags.isEmpty {
            currentTags.removeLast()
            delegate?.controlsViewController(self, didUpdateTags: currentTags, for: url)
            updateTagDisplay()
        } else {
            print("No tags to remove.")
        }
    }
    
    func updateTagDisplay() {
        guard let url = delegate?.currentImageURL(for: self) else {
            currentTagsDisplayLabel.stringValue = "Tidak ada gambar yang dipilih."
            setTaggingUI(enabled: false)
            return
        }
        
        let tags = delegate?.tags(for: self, url: url) ?? []
        if tags.isEmpty {
            currentTagsDisplayLabel.stringValue = "Tidak ada"
        } else {
            currentTagsDisplayLabel.stringValue = tags.joined(separator: ", ")
        }
        setTaggingUI(enabled: true)
        removeLastTagButton.isEnabled = !tags.isEmpty // Disable remove button if no tags exist
    }
    
    private func setTaggingUI(enabled: Bool) {
        tagComboBox.isEnabled = enabled
        addTagButton.isEnabled = enabled
        removeLastTagButton.isEnabled = enabled
    }
    
    @objc private func selectDirectoryClicked() {
        let openPanel = NSOpenPanel()
        openPanel.message = "Silakan pilih direktori"
        openPanel.prompt = "Pilih"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        
        if openPanel.runModal() == .OK, let url = openPanel.url {
            updateDirectoryLabel(with: url)
            saveDirectoryPermission(for: url)
            scanDirectoryAndInformDelegate(at: url)
        }
    }
    
    private func updateDirectoryLabel(with url: URL) {
        directoryLabel.stringValue = "Direktori: \(url.lastPathComponent)"
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

// MARK: - NSComboBox Delegate & DataSource
extension ControlsViewController: NSComboBoxDataSource, NSComboBoxDelegate {
    
    // --- DATA SOURCE METHODS ---
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return filteredTags.count
    }
    
    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        guard index < filteredTags.count else { return nil }
        return filteredTags[index]
    }
    
    // --- DELEGATE METHODS for filtering ---
    func comboBox(_ comboBox: NSComboBox, completedString string: String) -> String? {
        // This provides autocompletion
        return allTags.first { $0.lowercased().hasPrefix(string.lowercased()) }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        guard let comboBox = obj.object as? NSComboBox else { return }
        
        let filterString = comboBox.stringValue
        if filterString.isEmpty {
            filteredTags = allTags
        } else {
            filteredTags = allTags.filter {
                $0.lowercased().contains(filterString.lowercased())
            }
        }
        comboBox.reloadData()
    }
    
    // --- NEW: Handle Enter Key Press ---
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(insertNewline(_:)) {
            // User pressed Enter, so treat it like a button click.
            self.addTagTapped()
            return true // We handled the command.
        }
        // For all other commands, use the default behavior.
        return false
    }
}
