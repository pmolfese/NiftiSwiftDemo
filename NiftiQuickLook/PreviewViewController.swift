import Cocoa
import Quartz

class PreviewViewController: NSViewController, QLPreviewingController {
    private var quadView: NiftiQuadView!

    override var nibName: NSNib.Name? { nil }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 600))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        quadView = NiftiQuadView(frame: self.view.bounds)
        quadView.autoresizingMask = [.width, .height]
        self.view.addSubview(quadView)
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        NSLog("preparing preview...");
        if let nifti = NiftiImage(filename: url.path) {
            DispatchQueue.main.async { self.quadView.niftiImage = nifti }
            handler(nil)
        } else {
            let error = NSError(domain: "NiftiQuickLook", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load NIfTI file."])
            handler(error)
        }
    }
}
