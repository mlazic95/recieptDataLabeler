/*
See LICENSE folder for this sample’s licensing information.

Abstract:
App delegate.
*/

import Cocoa
import Vision
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, VisionViewDelegate, NSSearchFieldDelegate, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var imageView: VisionView!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var progressView: ProgressView!
    @IBOutlet weak var collectionView: NSCollectionView!
    
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet var ocrTextView: NSTextView!
    
    let fm = FileManager.default
    let pathRoot = "/Users/markolazic/Desktop/Receipt Labeler/MyFirstImageReader/"
    let recieptsFolder = "processedReceipts/"  // "reciepts/"
    let deletedFolder = "deleted/"
    let skippedFolder =  "skipped/"
    let doneFolder = "done/"
    let labelsFolder = "labels/"
    var items = [String]()
    var index: Int = 0
    var ocrResult = [TextItem]()
    var rawOcrResult: String!
    var labels = [LabelItem]()
    var rotate = false
    
    let classes = ["vendor", "date", "address", "total_price", "currency", "tax_rate", "product"]
    
    var recieptsPath: String {
        get {
            return pathRoot + recieptsFolder
        }
    }
    
    var donePath: String {
        get {
            return pathRoot + doneFolder
        }
    }
    
    var skippedPath: String {
        get {
            return pathRoot + skippedFolder
        }
    }
    
    var labelsPath: String {
        get {
            return pathRoot + labelsFolder
        }
    }
    
    var deletedPath: String {
        get {
            return pathRoot + deletedFolder
        }
    }
    
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.servicesProvider = self
        // Get the document directory url
        
        do {
            items = try fm.contentsOfDirectory(atPath: recieptsPath)
            
        } catch (let error){
            print(error.localizedDescription)
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(NSNib(nibNamed: "ItemCell", bundle: nil), forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ItemCell"))
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 250, height: 100)
        collectionView.collectionViewLayout = flowLayout

        let image = NSImage(byReferencingFile: recieptsPath + items[index])
        self.imageView.image = image
        addDefaultClasses()
        collectionView.reloadData()
        
    }
    @IBAction func skipPressed(_ sender: NSButton) {
        do {
            let date = Date()
            try fm.moveItem(at: URL(fileURLWithPath: recieptsPath + items[index]), to: URL(fileURLWithPath: skippedPath +  date.description + "_" + items[index]))
            index+=1
            ocrResult.removeAll()
            labels.removeAll()
            addDefaultClasses()
            collectionView.reloadData()
            let image = NSImage(byReferencingFile: recieptsPath + items[index])
            self.imageView.image = image
        } catch(let error) {
            print(error)
        }
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        do {
            let date = Date()
            try fm.moveItem(at: URL(fileURLWithPath: recieptsPath + items[index]), to: URL(fileURLWithPath: deletedPath +  date.description + "_" + items[index]))
            index+=1
            ocrResult.removeAll()
            labels.removeAll()
            addDefaultClasses()
            collectionView.reloadData()
            let image = NSImage(byReferencingFile: recieptsPath + items[index])
            self.imageView.image = image
        } catch {}
    }
    
    
    @IBAction func addPressed(_ sender: NSButton) {
        labels.append(LabelItem(text: nil, label: "product", price: nil, amount: nil))
        collectionView.reloadData()
    }
    
    func dialogOKCancel(question: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    
    @IBAction func donePressed(_ sender: NSButton) {
        if progressView.isRunning {
            return
        }
        labels = labels.filter({$0.text != nil})
        if let label = labels.first(where: { $0.label == "product" && $0.price == nil}) {
            _ = dialogOKCancel(question: "'" + label.text! + "' does not have a price", text: "Add price or remove the product to preceed")
            collectionView.reloadData()
            return
        }
        let date = Date()
        do {
            try fm.moveItem(at: URL(fileURLWithPath: recieptsPath + items[index]), to: URL(fileURLWithPath: donePath +  date.description + ".jpg"))
        } catch {}
        saveResult(name: date.description)
        index+=1
        ocrResult.removeAll()
        labels.removeAll()
        addDefaultClasses()
        collectionView.reloadData()
        ocrTextView.string = ""
        let image = NSImage(byReferencingFile: recieptsPath + items[index])
        self.imageView.image = image
    }
    
    func addDefaultClasses() {
        for className in classes {
            labels.append(LabelItem(text: nil, label: className, price: nil, amount: nil))
        }
    }
    
    func saveResult(name: String) {
        do {
            var ocrData: [[String: Any]] = [[String: Any]]()
            for item in ocrResult {
                let bottomLeft = NSStringFromPoint(item.rect.0)
                let bottomRight = NSStringFromPoint(item.rect.1)
                let topRight = NSStringFromPoint(item.rect.2)
                let topLeft = NSStringFromPoint(item.rect.3)
                let dict = ["text": item.str, "rotation": item.angle, "box": NSStringFromRect(item.box), "bottomLeft": bottomLeft, "bottomRight": bottomRight, "topRight": topRight, "topLeft": topLeft ] as [String : Any]
                ocrData.append(dict)
            }
            var labelData: [String: Any] = [String: Any]()
            for className in classes {
                if className == "product" {
                    continue
                }
                if let text = labels.first(where: { $0.label == className })?.text {
                    labelData[className] = text
                }
            }
            let products = labels.filter({$0.label == "product"})
            var labeledProducts = [[String: Any]]()
            for product in products {
                var dict: [String: Any] = ["name": product.text!, "price": product.price!]
                if let amount  = product.amount {
                    dict["amount"] = amount
                }
                labeledProducts.append(dict)
            }
            labelData["products"] = labeledProducts
            //Convert to Data
            let ocrJson = try JSONSerialization.data(withJSONObject: ocrData, options: JSONSerialization.WritingOptions.prettyPrinted)
            let labelJson = try JSONSerialization.data(withJSONObject: labelData, options: JSONSerialization.WritingOptions.prettyPrinted)
            //Convert back to string. Usually only do this for debugging
            if let ocrString = String(data: ocrJson, encoding: String.Encoding.utf8), let labelsString = String(data: labelJson, encoding: String.Encoding.utf8) {
               try ocrString.write(to: URL(fileURLWithPath: labelsPath + "text/" + name + "_text_items.json"), atomically: true, encoding: .utf8)
               try labelsString.write(to: URL(fileURLWithPath: labelsPath + "labels/" + name + "_labels.json"), atomically: true, encoding: .utf8)
               //try rawOcrResult.write(to: URL(fileURLWithPath: labelsPath + "raw/" +  name + "_raw_text.txt"), atomically: true, encoding: .utf8)
            }
        } catch (let error) {
            print(error)
        }
    }
    
    // MARK: Results filtering / highlighting
    @IBAction func highlightResults(_ sender: NSMenuItem) {
        // Flip menu item state
        if sender.state == NSControl.StateValue.on {
            sender.state = NSControl.StateValue.off
        } else {
            sender.state = NSControl.StateValue.on
        }
        imageView.annotationLayer.isHidden = (sender.state == NSControl.StateValue.off)
    }

    
    // MARK: Request cancellation
    @IBAction func cancelCurrentRequest(_ sender: NSButton) {
        textRecognitionRequest.cancel()
        progressView.isRunning = false
    }
    
    // MARK: Text recognition request options
    var recognitionLevel: VNRequestTextRecognitionLevel = VNRequestTextRecognitionLevel.accurate {
        didSet { performOCRRequest() }
    }
    @IBAction func changeRecognitionLevel(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem else {
            return
        }
        switch selectedItem.identifier!.rawValue {
        case "fast":
            recognitionLevel = VNRequestTextRecognitionLevel.fast
        default:
            recognitionLevel = VNRequestTextRecognitionLevel.accurate
        }
    }
    
    var useCPUOnly: Bool = false {
        didSet { performOCRRequest() }
    }
    @IBAction func changeUseCPUOnly(_ sender: NSMenuItem) {
        // Flip menu item state.
        if sender.state == NSControl.StateValue.on {
            sender.state = NSControl.StateValue.off
        } else {
            sender.state = NSControl.StateValue.on
        }
        useCPUOnly = (sender.state == NSControl.StateValue.on)
    }
    
    var useLanguageModel: Bool = true {
        didSet { performOCRRequest() }
    }
    @IBAction func changeUseLanguageModel(_ sender: NSButton) {
        useLanguageModel = (sender.state == NSControl.StateValue.on)
    }
    
    var minTextHeight: Float = 0 {
        didSet { performOCRRequest() }
    }
    @IBAction func changeMinTextHeight(_ sender: NSTextField) {
        minTextHeight = sender.floatValue
    }
    
    var results: [VNRecognizedTextObservation]?
    var requestHandler: VNImageRequestHandler?
    var textRecognitionRequest: VNRecognizeTextRequest!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Set up UI.
        progressView.isRunning = false
        imageView.delegate = self
        imageView.setupLayers()
        window.makeFirstResponder(imageView)
        
        // Set up the request.
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
    }
    
    func imageDidChange(toImage image: NSImage?) {
        guard let newImage = image else { return }
        ocrResult.removeAll()

        if let cgImage = newImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            // Set up the request handler.
            requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // Perform the request.
            performOCRRequest()
        } else {
            // Clean up Vision objects
            textRecognitionRequest.cancel()
            requestHandler = nil
            
            // Clean up UI.
            imageView.annotationLayer.results = []
            progressView.isRunning = false
        }
    }
    
    func updateRequestParameters() {
        // Update recognition level.
        switch recognitionLevel {
        case VNRequestTextRecognitionLevel.fast:
            textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.fast
        default:
            textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevel.accurate
        }
        
        // Update minimum text height.
        textRecognitionRequest.minimumTextHeight = self.minTextHeight
        
        // Update language-based correction.
        textRecognitionRequest.usesLanguageCorrection = self.useLanguageModel
        
        textRecognitionRequest.recognitionLanguages = ["swe", "en"]
        
        // Update CPU-only flag.
        textRecognitionRequest.usesCPUOnly = self.useCPUOnly
    }
    
    func performOCRRequest() {
        // Reset the previous request.
        textRecognitionRequest.cancel()
        imageView.annotationLayer.results = []
        
            updateRequestParameters()
            progressView.isRunning = true
            
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInteractive).async { [unowned self] in
            do {
                try self.requestHandler?.perform([self.textRecognitionRequest])
            } catch _ {}
        }
    }
    
    func calculateMedian(array: [CGFloat]) -> CGFloat {
        // Array should be sorted
        let sorted = array.sorted()
        let length = array.count
        
        // handle when count of items is even
        if (length % 2 == 0) {
            return (CGFloat(sorted[length / 2 - 1]) + CGFloat(sorted[length / 2])) / 2.0
        }
        
        // handle when count of items is odd
        return CGFloat(sorted[length / 2])
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [unowned self] in
            self.results = self.textRecognitionRequest.results as? [VNRecognizedTextObservation]
            
            var angles = [CGFloat]()
            // Update results display in the image view.
            if let results = self.results {
                var displayResults: [((CGPoint, CGPoint, CGPoint, CGPoint), String)] = []
                for observation in results {
                    let candidate: VNRecognizedText = observation.topCandidates(1)[0]
                    let candidateBounds = (observation.bottomLeft, observation.bottomRight, observation.topRight, observation.topLeft)
                    displayResults.append((candidateBounds, candidate.string))
                    let x1 = observation.topLeft.x
                    let y1 = observation.topLeft.y
                    let x2 = observation.bottomLeft.x
                    let y2 = observation.bottomLeft.y
                    let diffs = (x1-x2, y1-y2)
                    let rotation = atan(diffs.0/diffs.1) * 180.0 / CGFloat.pi
                    self.ocrResult.append(TextItem(str: observation.topCandidates(1)[0].string, box: observation.boundingBox, rect: candidateBounds, angle: rotation))
                    angles.append(rotation)
                }
                if self.rotate {
                    let median = self.calculateMedian(array: angles)
                    if median != 0 {
                        self.imageView.image = self.imageView.image!.imageRotatedByDegreess(degrees: median)
                    } else {
                        self.progressView.isRunning = false
                    }
                } else {
                    self.progressView.isRunning = false
                }
                
                self.imageView.annotationLayer.results = displayResults
                
            }
            // Update transcript view.
            if let results = self.results {
                var transcript: String = ""
                for observation in results {
                    transcript.append(observation.topCandidates(1)[0].string)
                    transcript.append(" ")
                }
                self.ocrTextView.string = transcript
                self.rawOcrResult = transcript
            }
        }
    }
}

extension AppDelegate: NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return labels.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ItemCell"), for: indexPath) as? ItemCell else { return NSCollectionViewItem() }
        item.setText(item: labels[indexPath.item])
        item.classButton.removeAllItems()
        item.classButton.addItems(withTitles: classes)
        if let label = labels[indexPath.item].label {
            item.labelName = label
        }
        item.index = indexPath.item
        item.delegate = self
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let label = labels[indexPath.item].label
        if label == "product" {
            return NSSize(width: 250, height: 100)
        } else {
            return NSSize(width: 250, height: 60)
        }
    }
    
}

extension AppDelegate: ItemCelldDelegate {

    func itemTapped(index: Int) {
        let candidate = ocrResult[index]
        self.imageView.annotationLayer.results = [(candidate.rect, candidate.str)]
    }
    
    func textChanged(newText: String, index: Int) {
        labels[index].text = newText
    }
    
    func priceChanged(price: Float, index: Int) {
        labels[index].price = price
    }
    
    func amountChanged(amount: Int, index: Int) {
        labels[index].amount = amount
    }
    
    func labelSet(label: String, index: Int) {
        labels[index].label = label
        collectionView.reloadData()
    }
    
    func removeTapped(index: Int) {
        labels.remove(at: index)
        collectionView.reloadData()
    }
}

protocol ItemCelldDelegate {
    func textChanged(newText: String, index: Int)
    func priceChanged(price: Float, index: Int)
    func amountChanged(amount: Int, index: Int)
    func labelSet(label: String, index: Int)
    func itemTapped(index: Int)
    func removeTapped(index: Int)
}

extension NSImage {
    public func imageRotatedByDegreess(degrees:CGFloat) -> NSImage {

        var imageBounds = NSZeroRect ; imageBounds.size = self.size
        let pathBounds = NSBezierPath(rect: imageBounds)
        var transform = NSAffineTransform()
        transform.rotate(byDegrees: degrees)
        pathBounds.transform(using: transform as AffineTransform)
        let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y, pathBounds.bounds.size.width, pathBounds.bounds.size.height )
        let rotatedImage = NSImage(size: rotatedBounds.size)

        //Center the image within the rotated bounds
        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
        imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)

        // Start a new transform
        transform = NSAffineTransform()
        // Move coordinate system to the center (since we want to rotate around the center)
        transform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
        transform.rotate(byDegrees: degrees)
        // Move the coordinate system bak to normal
        transform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
        // Draw the original image, rotated, into the new image
        rotatedImage.lockFocus()
        transform.concat()
        self.draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()

        return rotatedImage
    }
}

