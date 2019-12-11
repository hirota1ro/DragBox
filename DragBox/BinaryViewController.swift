//
//  BinaryViewController.swift
//  DragBox
//
//  Created by HIROTA Ichiro on 2019/01/11.
//  Copyright © 2019 HIROTA Ichiro. All rights reserved.
//

import UIKit

class BinaryViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    var url: URL?

    // weak var imageView: UIBinaryView?

    var docIC: UIDocumentInteractionController?

    override func viewDidLoad() {
        super.viewDidLoad()

        // DispatchQueue.global(qos: .background).async {
        //     let image = self.loadOnWorkerThread()
        //     DispatchQueue.main.async {
        //         self.startOnWorkerThread(image: image)
        //     }
        // }
    }

    // func loadOnWorkerThread() -> UIBinary? {
    //     guard let url = url else {
    //         return nil
    //     }
    //     guard let data = try? Data(contentsOf: url) else {
    //         return nil
    //     }
    //     return UIBinary(data: data)
    // }

    // func startOnWorkerThread(image: UIBinary?) {
    //     guard let image = image else {
    //         return
    //     }
    //     let imageView = UIBinaryView(image: image)
    //     scrollView.addSubview(imageView)
    //     scrollView.contentSize = image.size
    //     self.imageView = imageView
    // }

    @IBAction func tapActionItem(_ sender: UIBarButtonItem) {
        guard let url = url else {
            return
        }
        let docIC = UIDocumentInteractionController(url: url)
        self.docIC = docIC
        docIC.delegate = self
        docIC.presentOpenInMenu(from: sender, animated: true)
    }

    // @IBAction func tapCopyItem(_ sender: UIBarButtonItem) {
    //     guard let image = imageView?.image else {
    //         return
    //     }
    //     UIPasteboard.general.image = image
    // }
}

extension BinaryViewController: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        self.docIC = nil
    }
}

extension BinaryViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? { return nil }
}
