//
//  ViewController.swift
//  NiftiSwift
//
//  Created by Molfese, Peter  [E] on 8/12/25.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var quadView: NiftiQuadView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    
    var nifti: NiftiImage? {
            didSet {
                guard let nifti = nifti else { return }
                quadView.niftiImage = nifti
            }
        }
    
    
    @IBAction func openButtonClicked(_ sender: Any) {
            let panel = NSOpenPanel()
            panel.title = "Open NIFTI File"
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false

            panel.begin { [weak self] response in
                guard response == .OK, let url = panel.url else { return }
                if let nifti = NiftiImage(filename: url.path) {
                    DispatchQueue.main.async {
                        self?.quadView.niftiImage = nifti
                    }
                }
            }
        }
}

