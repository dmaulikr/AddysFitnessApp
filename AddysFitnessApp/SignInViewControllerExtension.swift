//
//  SignInViewControllerExtensions.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.14
//
//

import Foundation
import AWSCognitoIdentityProvider
import AWSMobileHubHelper
import AWSCognitoUserPoolsSignIn

// Extension containing methods which call different operations on Cognito User Pools (Sign In, Sign Up, Forgot Password)
extension SignInViewController {
    
    func handleCustomSignIn() {
        // set the interactive auth delegate to self, since this view controller handles the login process for user pools
        AWSCognitoUserPoolsSignInProvider.sharedInstance().setInteractiveAuthDelegate(self)
        self.handleLoginWithSignInProvider(AWSCognitoUserPoolsSignInProvider.sharedInstance())
    }
    
    func handleUserPoolSignUp () {
        let storyboard = UIStoryboard(name: "UserPools", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "SignUp")
        self.present(viewController, animated:true, completion:nil);
    }
    
    func handleUserPoolForgotPassword () {
        let storyboard = UIStoryboard(name: "UserPools", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ForgotPassword")
        self.present(viewController, animated:true, completion:nil);
    }
}

// Extension to adopt the `AWSCognitoIdentityInteractiveAuthenticationDelegate` protocol
extension SignInViewController: AWSCognitoIdentityInteractiveAuthenticationDelegate {
    
    // this function handles the UI setup for initial login screen, in our case, since we are already on the login screen, we just return the View Controller instance
    func startPasswordAuthentication() -> AWSCognitoIdentityPasswordAuthentication {
        return self
    }
    
    // prepare and setup the ViewController that manages the Multi-Factor Authentication
    func startMultiFactorAuthentication() -> AWSCognitoIdentityMultiFactorAuthentication {
        let storyboard = UIStoryboard(name: "UserPools", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "MFA")
        DispatchQueue.main.async(execute: {
            self.present(viewController, animated:true, completion:nil);
        })
        return viewController as! AWSCognitoIdentityMultiFactorAuthentication
    }
}

// Extension to adopt the `AWSCognitoIdentityPasswordAuthentication` protocol
extension SignInViewController: AWSCognitoIdentityPasswordAuthentication {
    
    func getDetails(_ authenticationInput: AWSCognitoIdentityPasswordAuthenticationInput, passwordAuthenticationCompletionSource: AWSTaskCompletionSource<AWSCognitoIdentityPasswordAuthenticationDetails>) {
        self.passwordAuthenticationCompletion = passwordAuthenticationCompletionSource as? AWSTaskCompletionSource<AnyObject>
    }
    
    func didCompleteStepWithError(_ error: Error?) {
        if let error = error as? NSError {
            DispatchQueue.main.async(execute: {
                
                let alert = UIAlertController(title: error.userInfo["__type"] as? String,
                                              message:error.userInfo["message"] as? String,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion:nil)
            })
        }
    }
}

// Extension to adopt the `AWSCognitoUserPoolsSignInHandler` protocol
extension SignInViewController: AWSCognitoUserPoolsSignInHandler {
    func handleUserPoolSignInFlowStart() {
        // check if both username and password fields are provided
        guard let username = self.customEmailField.text, !username.isEmpty,
            let password = self.customPasswordField.text, !password.isEmpty else {
                DispatchQueue.main.async(execute: {
                    let alert = UIAlertController(title: "Missing UserName / Password",
                                                  message:"Please enter a valid user name / password.",
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion:nil)
                })
                return
        }
        // set the task completion result as an object of AWSCognitoIdentityPasswordAuthenticationDetails with username and password that the app user provides
        self.passwordAuthenticationCompletion?.set(result: AWSCognitoIdentityPasswordAuthenticationDetails(username: username, password: password))
    }
}
