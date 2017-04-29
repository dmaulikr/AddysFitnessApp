//
//  ViewController.swift
//  AddysFitnessApp
//
//  Created by Tim Gilman on 3/6/17.
//  Copyright © 2017 Tharia LLC. All rights reserved.
//

import UIKit
import AWSMobileHubHelper
import os.log

var admin = ["test123"]

class InitialViewController: UIViewController {
    
    var signInObserver: AnyObject!
    var signOutObserver: AnyObject!
    var willEnterForegroundObserver: AnyObject!
    fileprivate let loginButton: UIBarButtonItem = UIBarButtonItem(title: nil, style: .done, target: nil, action: nil)
    
    
    @IBOutlet weak var foodIcon: UIImageView!
    
    @IBOutlet weak var workoutIcon: UIImageView!
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        
        os_log("Going to Sign in viewController", log: OSLog.default, type: .debug)
        presentSignInViewController()
        
        // create tapGestureRecognizer for images
        let tapWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleWorkoutIconTapped))
        let tapFoodsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleFoodIconTapped))
        
        // Optionally set the number of required taps, e.g., 2 for a double click
        tapWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        tapFoodsGestureRecognizer.numberOfTapsRequired = 1
        
        // Attach it to a view of your choice. If it's a UIImageView, remember to enable user interaction
        workoutIcon.isUserInteractionEnabled = true
        workoutIcon.addGestureRecognizer(tapWorkoutsGestureRecognizer)
        foodIcon.isUserInteractionEnabled = true
        foodIcon.addGestureRecognizer(tapFoodsGestureRecognizer)
        
        /*
        signInObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignIn, object: AWSIdentityManager.default(), queue: OperationQueue.main, using: {[weak self] (note: Notification) -> Void in
            guard let strongSelf = self else { return }
            os_log("Sign in observer signed in", log: OSLog.default, type: .debug)
            strongSelf.setupRightBarButtonItem()
        })
        
        signOutObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AWSIdentityManagerDidSignOut, object: AWSIdentityManager.default(), queue: OperationQueue.main, using: {[weak self](note: Notification) -> Void in
            guard let strongSelf = self else { return }
            os_log("Sign out observer signed out", log: OSLog.default, type: .debug)
            strongSelf.setupRightBarButtonItem()
        })
         */
        
        setupRightBarButtonItem()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(signInObserver)
        NotificationCenter.default.removeObserver(signOutObserver)
        NotificationCenter.default.removeObserver(willEnterForegroundObserver)
    }
    
    func handleWorkoutIconTapped() {
        os_log("Sending to workouts storyboard", log: OSLog.default, type: .debug)
        let storyboard = UIStoryboard(name: "Workouts", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "WorkoutsView")
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func handleFoodIconTapped() {
        os_log("Sending to Food storyboard", log: OSLog.default, type: .debug)
        let storyboard = UIStoryboard(name: "Food", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FoodView")
        self.navigationController!.pushViewController(viewController, animated: true)
    }
    
    func setupRightBarButtonItem() {
        navigationItem.rightBarButtonItem = loginButton
        navigationItem.rightBarButtonItem!.target = self
        
        if (AWSSignInManager.sharedInstance().isLoggedIn) {
            navigationItem.rightBarButtonItem!.title = NSLocalizedString("Sign-Out", comment: "Label for the logout button.")
            navigationItem.rightBarButtonItem!.action = #selector(InitialViewController.handleLogout)
        }

    }
    
    func presentSignInViewController() {
        if !AWSSignInManager.sharedInstance().isLoggedIn {
            let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "SignIn")
            self.present(viewController, animated: true, completion: nil)
        }
    }
    
    func handleLogout() {
        if (AWSSignInManager.sharedInstance().isLoggedIn) {
            AWSSignInManager.sharedInstance().logout(completionHandler: {(result: Any?, authState: AWSIdentityManagerAuthState, error: Error?) in
                self.navigationController!.popToRootViewController(animated: false)
                self.setupRightBarButtonItem()
                self.presentSignInViewController()
            })
            // print("Logout Successful: \(signInProvider.getDisplayName)");
        } else {
            assert(false)
        }
    }

}
