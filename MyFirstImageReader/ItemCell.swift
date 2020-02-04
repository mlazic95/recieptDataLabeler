//
//  ItemCell.swift
//  MyFirstImageReader
//
//  Created by Marko Lazic on 2020-01-27.
//  Copyright © 2020 Apple. All rights reserved.
//

import Cocoa

class ItemCell: NSCollectionViewItem {
    var index: Int!
    var delegate: ItemCelldDelegate!
    
    @IBOutlet weak var classButton: NSPopUpButton!
    @IBOutlet weak var text: NSTextField!
    @IBOutlet weak var priceLabel: NSTextField!
    @IBOutlet weak var priceText: NSTextField!
    @IBOutlet weak var amountLabel: NSTextField!
    @IBOutlet weak var amountText: NSTextField!
    
    var labelName: String {
        get {
            return classButton.titleOfSelectedItem!
        }
        set {
            classButton.selectItem(withTitle: newValue)
            if newValue == "product" {
                priceLabel.isHidden = false
                priceText.isHidden = false
                amountLabel.isHidden = false
                amountText.isHidden = false
            } else {
                priceLabel.isHidden = true
                priceText.isHidden = true
                amountLabel.isHidden = true
                amountText.isHidden = true
            }
        }
    }
    
    @IBAction func classChanged(_ sender: NSPopUpButton) {
        labelName = sender.titleOfSelectedItem!
        delegate.labelSet(label: labelName, index: index)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        text.isHidden = false
        text.delegate = self
        priceText.delegate = self
        amountText.delegate = self
        priceLabel.isHidden = true
        priceText.isHidden = true
        amountLabel.isHidden = true
        amountText.isHidden = true
    }
    
    func setText(item: LabelItem) {
        text.stringValue = item.text ?? ""
        if let amount = item.amount {
            amountText.stringValue = "\(amount)"
        } else {
            amountText.stringValue = ""
        }
        
        if let price = item.price {
            priceText.stringValue = "\(price)"
        } else {
            priceText.stringValue = ""
        }
    }
    
    
    @IBAction func removePressed(_ sender: Any) {
        delegate.removeTapped(index: index)
    }
}

extension ItemCell: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
      let field = obj.object as! NSTextField
        if field.identifier?.rawValue == "text"{
            delegate.textChanged(newText: field.stringValue, index: index)
        } else if field.identifier?.rawValue == "price" {
            let price = (field.stringValue as NSString).floatValue
            if price != 0.0 || Int(field.stringValue) == 0 {
                delegate.priceChanged(price: price , index: index)
            } else {
                print("Not a float")
            }
        } else if field.identifier?.rawValue == "amount" {
            if let amount = Int(field.stringValue) {
                delegate.amountChanged(amount: amount, index: index)
            } else {
                print("Not an int")
            }
        }
    }
}
