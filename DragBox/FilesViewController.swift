//
//  FilesViewController.swift
//  DragBox
//
//  Created by HIROTA Ichiro on 2019/01/11.
//  Copyright © 2019 HIROTA Ichiro. All rights reserved.
//

import UIKit
import PDFKit
import MobileCoreServices

class FilesViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var files: Files?
}

extension FilesViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = editButtonItem

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(FilesViewController.refreshAction(_:)), for: .valueChanged)
        tableView.refreshControl = refresh

        if self.files == nil {
            let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            self.files = Files(dir: docURL, observer: self)
            navigationItem.title = docURL.lastPathComponent
        }
        DispatchQueue.global(qos: .background).async {
            self.files?.reload()
        }
    }

    @objc func refreshAction(_ sender: UIRefreshControl) {
        DispatchQueue.global(qos: .background).async {
            self.files?.reload() { sender.endRefreshing() }
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    func remove(at indexPath: IndexPath) {
        files?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }
}

// MARK: - Navigation

extension FilesViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "image" {
            if let cell = sender as? UITableViewCell,
               let indexPath = tableView.indexPath(for: cell),
               let file = files?[indexPath.row],
               let imgVC = segue.destination as? ImageViewController {
                imgVC.url = file.url
                imgVC.navigationItem.title = file.name
            }
        }
        if segue.identifier == "pdf" {
            if let cell = sender as? UITableViewCell,
               let indexPath = tableView.indexPath(for: cell),
               let file = files?[indexPath.row],
               let pdfVC = segue.destination as? PdfViewController {
                pdfVC.url = file.url
                pdfVC.navigationItem.title = file.name
            }
        }
        if segue.identifier == "dir" {
            if let cell = sender as? UITableViewCell,
               let indexPath = tableView.indexPath(for: cell),
               let dir = files?[indexPath.row],
               let filesVC = segue.destination as? FilesViewController {
                if let dirURL = dir.url {
                    filesVC.files = Files(dir: dirURL, observer: filesVC)
                    filesVC.navigationItem.title = dir.name
                }
            }
        }
    }
}

extension FilesViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let file = files![indexPath.row]
        let cellID = file.isDir ? "dir" : cellType(mimeType: mimeTypeFromExt(file.ext)) ?? "binary"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        (cell as? FileCell)?.file = file
        return cell
    }

    static let mimeToCellType: [String: String] = [
      "image/png": "image",
      "image/jpeg": "image",
      "application/pdf": "pdf",
    ]

    private func cellType(mimeType: String?) -> String? {
        guard let mime = mimeType else {
            return nil
        }
        guard let cid = FilesViewController.mimeToCellType[mime] else {
            return nil
        }
        return cid
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

extension FilesViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            remove(at: indexPath)
        default:
            break
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // if let file = files?[indexPath.row] {
        //     file.editMode = !file.editMode
        // }
    }

    public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let file = files?[indexPath.row] {
            file.editMode = false
        }
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
            completionHandler(true)
            self.remove(at: indexPath)
        }
        let swipeAction = UISwipeActionsConfiguration(actions: [delete])
        swipeAction.performsFirstActionWithFullSwipe = false
        return swipeAction
    }
}

extension FilesViewController {
    func openURL(inputURL: URL) -> Bool {
        guard let dstURL = files?.uniqURL(name: inputURL.lastPathComponent) else {
            return false
        }
        do {
            try FileManager.default.moveItem(at: inputURL, to: dstURL)
            print("\(#function) succeeded from=\(inputURL) to=\(dstURL)")
            return true
        } catch let error {
            print("\(#function) error=\(error)")
            return false
        }
    }
}

class File {
    weak var owner: FileOwner?
    weak var observer: FileObserver?
    var editMode: Bool = false {
        didSet {
            if oldValue != editMode {
                observer?.editModeChanged(file: self)
            }
        }
    }
    var name: String {
        didSet {
            owner?.updated(file: self)
        }
    }
    var thumbImage: UIImage? {
        didSet {
            owner?.updated(file: self)
        }
    }
    lazy var attributes: [FileAttributeKey: Any]? = {
        guard let path = owner?.content(for: name).path else {
            return nil
        }
        return try? FileManager.default.attributesOfItem(atPath: path)
    }()

    init(name: String, owner: Files) {
        self.name = name
        self.owner = owner
    }
}

extension File {

    var isDir: Bool { return url?.isDir ?? false }

    var url: URL? { return owner?.content(for: name) }

    var ext: String { return URL(fileURLWithPath: name).pathExtension }

    var date: Date? { return attributes?[.modificationDate] as? Date }

    var size: UInt64? { return attributes?[.size] as? UInt64 }

    func createThumbImage() {
        self.thumbImage = url?.thumbnailImage(size: CGSize(width: 40,  height: 40))
    }

    func remove() {
        if let url = url {
            do {
                try FileManager.default.removeItem(at: url)
                print("\(#function) succeeded=\(url)")
            } catch let error {
                print("\(#function) error=\(error)")
            }
        }
    }

    func rename(to: String) -> Bool {
        if let fromURL = url,
           let toURL = owner?.content(for: to) {
            do {
                try FileManager.default.moveItem(at: fromURL, to: toURL)
                print("\(#function) succeeded=\(toURL)")
                return true
            } catch let error {
                print("\(#function) error=\(error)")
            }
        }
        return false
    }
}

protocol FileOwner: AnyObject {
    func content(for name: String) -> URL
    func updated(file: File)
}

protocol FileObserver: AnyObject {
    func editModeChanged(file: File)
}

class Files {
    weak var observer: FilesObserver?
    var dir: URL
    var files: [File]?

    init(dir: URL, observer: FilesObserver) {
        self.dir = dir
        self.observer = observer
    }

    var count: Int { return files?.count ?? 0 }
    subscript(i: Int) -> File { return files![i] }

    func reload(completion: (()->Void)? = nil) {
        files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).map { (url) -> File in
            return File(name: url.lastPathComponent, owner: self)
        }
        files?.forEach { (file) in
            DispatchQueue.global(qos: .background).async {
                file.createThumbImage()
            }
        }
        observer?.reloaded(files: self, completion: completion)
    }

    func uniqURL(name: String) -> URL {
        // 名前を本体と拡張子に分離します (ex. name="a.pdf"→ body=a", ext="pdf")
        let nameURL = URL(fileURLWithPath: name)
        let ext = nameURL.pathExtension
        let bodyURL = nameURL.deletingPathExtension()
        let body = bodyURL.lastPathComponent
        // 存在しない名前を検索します
        var n = 2
        var newURL = dir.appendingPathComponent(name)
        while FileManager.default.fileExists(atPath: newURL.path) {
            let newName = "\(body)(\(n))"
            newURL = dir.appendingPathComponent(newName).appendingPathExtension(ext)
            n += 1
        }
        return newURL
    }

    func remove(at index: Int) {
        if let file = files?.remove(at: index) {
            file.remove()
        }
    }
}
extension Files: FileOwner {
    func content(for name: String) -> URL {
        return dir.appendingPathComponent(name)
    }
    func updated(file: File) {
        guard let index = files?.firstIndex(where: { $0 === file }) else {
            return
        }
        observer?.updated(files: self, at: index)
    }
}

protocol FilesObserver: AnyObject {
    func reloaded(files: Files, completion: (()->Void)?)
    func updated(files: Files, at index: Int)
}

extension FilesViewController: FilesObserver {
    func reloaded(files: Files, completion: (()->Void)?) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            completion?()
        }
    }
    func updated(files: Files, at index: Int) {
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .fade)
        }
    }
}

class FileCell: UITableViewCell {
    @IBOutlet weak var thumb: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var field: UITextField!

    var file: File? {
        didSet {
            if let file = file {
                file.observer = self
                configure(file: file)
            }
        }
    }

    func configure(file: File) {
        label.text = file.name
        field.text = file.name
        let timestamp = { () -> String in
            if let date = file.date {
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy-MM-dd hh:mm:ss"
                return fmt.string(from: date)
            }
            return "N/A"
        }()
        let bytesize = { () -> String in
            if let size = file.size {
                return "\(size) bytes"
            }
            return "N/A"
        }()
        detail.text = "\(timestamp) \(bytesize)"
        thumb.image = file.thumbImage
    }
}

extension FileCell: UITextFieldDelegate {
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        let beginning = textField.beginningOfDocument
        textField.selectedTextRange = textField.textRange(from: beginning, to: beginning)
    }
    public func textFieldDidEndEditing(_ textField: UITextField) {
        if let file = file,
           let text = textField.text {
            if text != file.name {
                if file.rename(to: text) {
                    file.name = text
                }
            }
        }
    }
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        file?.editMode = false
        return true
    }
}

extension FileCell: FileObserver {
    func editModeChanged(file: File) {
        label.isHidden = file.editMode
        field.isHidden = !file.editMode
        if file.editMode {
            field.becomeFirstResponder()
        } else {
            field.resignFirstResponder()
        }
    }
}

extension URL {
    var isDir: Bool {
        var f: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &f) && f.boolValue
    }

    func thumbnailImage(size: CGSize) -> UIImage? {
        switch mimeTypeFromExt(pathExtension) {
        case "image/png", "image/jpeg":
            return thumbFromIMG(size: size)
        case "application/pdf":
            return thumbFromPDF(size: size)
        default:
            return nil
        }
    }

    func thumbFromIMG(size: CGSize) -> UIImage? {
        guard let data = try? Data(contentsOf: self) else {
            print("\(#function) no data")
            return nil
        }
        guard let image = UIImage(data: data) else {
            print("\(#function) not image")
            return nil
        }
        let scale = image.size.zoomScale(fitTo: size)
        return image.resized(scale: scale)
    }

    func thumbFromPDF(size: CGSize) -> UIImage? {
        guard let doc = PDFDocument(url: self) else {
            print("\(#function) no document")
            return nil
        }
        guard let page = doc.page(at: 0) else {
            print("\(#function) no page")
            return nil
        }
        return page.thumbnail(of: size, for: .cropBox)
    }
}

extension CGSize {
    func zoomScale(fitTo: CGSize) -> CGFloat { return Swift.min(fitTo.width / width, fitTo.height / height) }
    static func * (a: CGSize, b: CGFloat) -> CGSize { return CGSize(width: a.width * b, height: a.height * b) }
}

extension UIImage {
    func resized(scale: CGFloat) -> UIImage {
        return UIGraphicsImageRenderer(size: self.size * scale).image { (ctx) in
            ctx.cgContext.scaleBy(x: scale, y: scale)
            self.draw(at: .zero)
        }
    }
}

/** obtain mime-type as string from extension string
 * @param ext extension of file name (ex. "pdf")
 * @return mime-type (ex. "application/pdf")
 */
func mimeTypeFromExt(_ ext: String) -> String? {
    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, ext as NSString, nil)?.takeRetainedValue() {
        if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
        }
    }
    return nil
}
