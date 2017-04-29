//
//  AddStepsViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 4/26/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import WebKit
import AVFoundation
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC

class AddStepsViewController: UIViewController, UITextFieldDelegate {
    
    var stepFields: [UITextField] = []
    var stepStackViewArr: [UIStackView] = []
    var activeField: UITextField?
    let screenSize = UIScreen.main.bounds
    var screenWidth: CGFloat!
    var steps: [String] = []
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var stepStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var stepText: UITextField!
    @IBOutlet weak var stepStackView: UIStackView!
    @IBOutlet weak var buttonStackView: UIStackView!
    
    override func viewDidLoad() {
        navigationItem.title = "Add Steps"
        let screenSize = UIScreen.main.bounds
        contentViewHeight.constant = screenSize.height
        screenWidth = screenSize.width
        
        stepFields.append(stepText)
        stepStackViewArr.append(stepStackView)
        
        loadSteps()
        
        self.stepText.delegate = self
        
        for case let button as UIButton in buttonStackView.subviews {
            button.layer.cornerRadius = 10
            button.layer.borderColor = UIColor.black.cgColor
            button.layer.borderWidth = 1
        }
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(AddStepsViewController.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(AddStepsViewController.keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    
    func loadSteps() {
        os_log("Load step", log: OSLog.default, type: .debug)
        for i in 0..<steps.count {
            if i ==  0 {
                stepText.text = steps[i]
            } else {
                addNewStackView(true, steps[i])
            }
        }
    }
    
    func verifyStepsAdded() -> Bool {
        for step in stepFields {
            if let stepText = step.text, stepText != "" {
                steps.append(stepText)
            }
        }
        
        return true;
    }
    
    func addNewStackView(_ insertText: Bool, _ text: String) {
        let newStackView = createStackView(insertText, text)
        
        stepStackViewArr.append(newStackView)
        
        buttonStackViewHeight.constant += 45
        contentViewHeight.constant += 45
        
        contentView.addSubview(newStackView)
    }

    @IBAction func addStepTapped(_ sender: Any) {
        os_log("Add new step", log: OSLog.default, type: .debug)
        
        addNewStackView(false, "")
        
    }
    
    
    @IBAction func finishStepsTapped(_ sender: Any) {
        if(verifyStepsAdded()) {
            os_log("Clicked finish going to unwind segue", log: OSLog.default, type: .debug)
            self.performSegue(withIdentifier: "unwindFromStepsToUploadFood", sender: self)
        } else {
            os_log("Error with verifying inputs", log: OSLog.default, type: .debug)
        }

    }
    
    func createStackView(_ insertText: Bool, _ step: String) -> UIStackView {
        let newStackView = UIStackView()
        newStackView.frame = CGRect(x: 8, y: self.stepStackViewArr[stepStackViewArr.count - 1].frame.origin.y + 45, width: screenWidth - 16, height: 30)
        newStackView.alignment = .fill
        newStackView.distribution = .fill
        newStackView.axis = .horizontal
        
        let newLabel = UILabel()
        newLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        newLabel.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        newLabel.textAlignment = .center
        newLabel.text = "\(stepFields.count + 1)."
        
        let newStepText = UITextField()
        if(insertText) {
            newStepText.text = step
        } else {
            newStepText.placeholder = "Enter Step"
        }
        
        newStepText.delegate = self
        newStepText.layer.cornerRadius = 5
        
        stepFields.append(newStepText)
        
        newStackView.addArrangedSubview(newLabel)
        newStackView.addArrangedSubview(newStepText)
        
        return newStackView
    }
    
    // MARK: - Keyboard
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeField = nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        os_log("Text field is being edited", log: OSLog.default, type: .debug)
        self.activeField = textField
    }
    
    func adjustingHeight(show:Bool, notification:NSNotification) {
        // 1
        var userInfo = notification.userInfo!
        // 2
        let keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        // 3
        let animationDurarion = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        // 4
        let changeInHeight = (keyboardFrame.height + 40) * (show ? 1 : -1)
        //5
        UIView.animate(withDuration: animationDurarion, animations: { () -> Void in
            self.contentViewHeight.constant += changeInHeight
        })
    }
    
    func keyboardWillShow(notification: NSNotification) {
        adjustingHeight(show: true, notification: notification)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        adjustingHeight(show: false, notification: notification)
    }
    
    func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: nil) { (_) -> Void in
            self.scrollView.contentSize.height = self.contentView.frame.height
        }
    }
    
    deinit {
        let notificationCenter = NotificationCenter.default
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }


}
