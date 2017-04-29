//
//  SignInViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/6/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import AWSMobileHubHelper
import AWSCognitoIdentityProvider

class SignInViewController: UIViewController {

    //MARK: - Properties
    @IBOutlet weak var customEmailField: UITextField!
    @IBOutlet weak var customPasswordField: UITextField!
    
    @IBOutlet weak var customSignInButton: UIButton!
    @IBOutlet weak var customCreateAccountButton: UIButton!
   
    @IBOutlet weak var customForgotPasswordButton: UIButton!
    
    
    @IBOutlet weak var customSignInImage: UIImageView!
    
    let signInImage = UIImage(named: "SignIn")
    
    var didSignInObserver: AnyObject!
    var passwordAuthenticationCompletion: AWSTaskCompletionSource<AnyObject>?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Sign In Loading.")
        
        // Custom UI Setup
        customSignInButton.addTarget(self, action: #selector(self.handleCustomSignIn), for: .touchUpInside)
        customCreateAccountButton.addTarget(self, action: #selector(self.handleUserPoolSignUp), for: .touchUpInside)
        customForgotPasswordButton.addTarget(self, action: #selector(self.handleUserPoolForgotPassword), for: .touchUpInside)
        
        customEmailField.delegate = self
        customPasswordField.delegate = self
    }
    
    func dimissController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Utility Methods
    
    func handleLoginWithSignInProvider(_ signInProvider: AWSSignInProvider) {
        AWSSignInManager.sharedInstance().login(signInProviderKey: signInProvider.identityProviderName, completionHandler: {(result: Any?, authState: AWSIdentityManagerAuthState, error: Error?) in
            print("result = \(String(describing: result)), error = \(String(describing: error))")
            // If no error reported by SignInProvider, discard the sign-in view controller.
            guard let _ = result else {
                self.showErrorDialog(signInProvider.identityProviderName, withError: error! as NSError)
                return
            }
            DispatchQueue.main.async(execute: {
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    func showErrorDialog(_ loginProviderName: String, withError error: NSError) {
        print("\(loginProviderName) failed to sign in w/ error: \(error)")
        let alertController = UIAlertController(title: NSLocalizedString("Sign-in Provider Sign-In Error", comment: "Sign-in error for sign-in failure."), message: NSLocalizedString("\(loginProviderName) failed to sign in w/ error: \(error)", comment: "Sign-in message structure for sign-in failure."), preferredStyle: .alert)
        let doneAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Label to cancel sign-in failure."), style: .cancel, handler: nil)
        alertController.addAction(doneAction)
        present(alertController, animated: true, completion: nil)
    }

}

extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
