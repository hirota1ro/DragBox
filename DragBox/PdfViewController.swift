//
//  PdfViewController.swift
//  DragBox
//
//  Created by HIROTA Ichiro on 2019/01/11.
//  Copyright © 2019 HIROTA Ichiro. All rights reserved.
//

import UIKit
import PDFKit

class PdfViewController: UIViewController {

    @IBOutlet weak var pdfView: PDFView!

    var url: URL?

    var docIC: UIDocumentInteractionController?

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.global(qos: .background).async {
            let pdf = self.loadOnWorkerThread()
            DispatchQueue.main.async {
                self.startOnWorkerThread(pdf: pdf)
            }
        }
    }

    func loadOnWorkerThread() -> PDFDocument? {
        guard let url = url else {
            return nil
        }
        return PDFDocument(url: url)
    }

    func startOnWorkerThread(pdf: PDFDocument?) {
        guard let pdf = pdf else {
            return
        }
        self.pdfView.document = pdf
    }

    @IBAction func tapActionItem(_ sender: UIBarButtonItem) {
        guard let url = url else {
            return
        }
        let docIC = UIDocumentInteractionController(url: url)
        self.docIC = docIC
        docIC.delegate = self
        docIC.presentOpenInMenu(from: sender, animated: true)
    }
}

extension PdfViewController: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
        self.docIC = nil
    }
}
