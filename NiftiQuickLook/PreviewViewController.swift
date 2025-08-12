
import Cocoa
import Quartz

// This class is the entry point for your Quick Look extension.
// It's responsible for loading the NIfTI file and presenting a view
// that can display the image data.
class PreviewViewController: NSViewController, QLPreviewingController {
    
    // This is the custom view that will render the NIfTI slices.
    // It is declared as an implicitly unwrapped optional because it will be
    // initialized later in viewDidLoad().
    private var quadView: NiftiQuadView!

    // The nibName property is not used here because we are creating the view
    // programmatically instead of loading it from a NIB or storyboard.
    override var nibName: NSNib.Name? {
        return nil
    }

    // Called after the view controller's view has been loaded into memory.
    // This is the ideal place to set up the quadView.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the NiftiQuadView with the bounds of the main view.
        quadView = NiftiQuadView(frame: self.view.bounds)
        
        // Ensure the quadView resizes automatically when the window size changes.
        quadView.autoresizingMask = [.width, .height]
        
        // Add the quadView as a subview to this controller's main view.
        self.view.addSubview(quadView)
    }

    // This is the core method of the QLPreviewingController protocol.
    // The system calls this function to ask the extension to prepare a preview
    // for the file at the given URL.
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        
        // Attempt to load the NIfTI image using your NiftiImage class.
        if let nifti = NiftiImage(filename: url.path) {
            
            // If the file loads successfully, assign the loaded image to the quadView.
            // The didSet observer in NiftiQuadView will automatically trigger a redraw.
            DispatchQueue.main.async {
                self.quadView.niftiImage = nifti
            }
            
            // Indicate that the preview was prepared without any errors.
            handler(nil)
        } else {
            // If the file fails to load, create an error and pass it to the handler.
            let error = NSError(domain: "NiftiQuickLook", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load NIfTI file."])
            handler(error)
        }
    }
}
