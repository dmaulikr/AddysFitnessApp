//
//  UserFilesViewController.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.10
//

import UIKit
import WebKit
import AVKit
import AVFoundation
import MediaPlayer
import MobileCoreServices
import AWSMobileHubHelper
import AWSDynamoDB
import os.log

import ObjectiveC

let WorkoutVideosDirectoryName = "public/workoutVideos/"
let WorkoutImagesDirectoryName = "public/workoutImages/"
let UserFilesPrivateDirectoryName = "private"
private var cellAssociationKey: UInt8 = 0

class WorkoutsViewController: UITableViewController {
    var prefix: String!
    
    var vidContent: [AWSContent]?
    var vidDetails = [String: [Workouts]]()
    var workouts = [String: [WorkoutVids]]()
    var selected: String!
    var loadedDetails: [String: Bool] = ["armVideos": false, "legVideos": false, "abVideos": false, "cardioVideos": false]
    
    fileprivate var manager: AWSUserFileManager!
    fileprivate var identityManager: AWSIdentityManager!
    fileprivate var contents: [AWSContent]?
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var marker: String?
    fileprivate var refresh: Bool!
    fileprivate var didLoadAllVideos: Bool!
    
    @IBOutlet weak var armWorkoutsLabel: UILabel!
    @IBOutlet weak var legWorkoutsLabel: UILabel!
    @IBOutlet weak var cardioWorkoutsLabel: UILabel!
    @IBOutlet weak var abWorkoutsLabel: UILabel!
    
    // MARK:- View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        manager = AWSUserFileManager.defaultUserFileManager()
        identityManager = AWSIdentityManager.default()
        
        DispatchQueue.main.async {
            self.loadMoreContents()
        }
        
        // Sets up the UIs.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(WorkoutsViewController.showContentManagerActionOptions(_:)))
        navigationItem.title = "MVPFit"
        
        // Sets up the date formatter.
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        
        //tableView.estimatedRowHeight = tableView.rowHeight
        //tableView.rowHeight = UITableViewAutomaticDimension
        didLoadAllVideos = false
        refresh = false
        
        if let prefix = prefix {
            print("Prefix already initialized to \(prefix)")
        } else {
            self.prefix = "\(WorkoutVideosDirectoryName)"
        }
        
        setIcons()
        selected = "armVideos"
        handleCategories()
        
        self.refreshControl?.addTarget(self, action: #selector(WorkoutsViewController.handleRefresh(_:)), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //refreshContents()
        //updateUserInterface()
        //loadMoreContents()
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        refresh = true

        os_log("handleRefresh", log: OSLog.default, type: .debug)
        
        self.loadVideoDetails()
        
        refreshControl.endRefreshing()
    }
    
    fileprivate func updateUserInterface() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    // MARK:- Content Manager user action methods
    func showContentManagerActionOptions(_ sender: AnyObject) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let uploadObjectAction = UIAlertAction(title: "Upload", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.showImagePicker()
        })
        alertController.addAction(uploadObjectAction)
        
        let refreshAction = UIAlertAction(title: "Refresh", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.refreshContents()
        })
        alertController.addAction(refreshAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func refreshContents() {
        marker = nil
        loadMoreContents()
    }
    
    fileprivate func addVideos() {
        if let workouts = workouts[selected], workouts.count > 0 {
            if let contents = self.contents, contents.count > 0 {
                for workout in workouts {
                    let key = self.prefix + workout.name! + ".mp4"
                    if let i = contents.index(where: { $0.key == key }) {
                        workout.content = contents[i]
                    }
                }
            }
        }
    }
    
    fileprivate func loadMoreContents() {
        manager.listAvailableContents(withPrefix: prefix, marker: marker) {[weak self] (contents: [AWSContent]?, nextMarker: String?, error: Error?) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.showSimpleAlertWithTitle("Error", message: "Failed to load the list of contents.", cancelButtonTitle: "OK")
                print("Failed to load the list of contents. \(error)")
            }
            if let contents = contents, contents.count > 0 {
                strongSelf.contents = contents
                if let nextMarker = nextMarker, !nextMarker.isEmpty {
                    strongSelf.didLoadAllVideos = false
                } else {
                    strongSelf.didLoadAllVideos = true
                }
                strongSelf.marker = nextMarker
                strongSelf.addVideos()
            }
            
            if strongSelf.loadedDetails[strongSelf.selected]! {
                strongSelf.updateUserInterface()
            }
        }
    }
    
    func loadVideoDetails() {
        let completionHandler = {(response: AWSDynamoDBPaginatedOutput?, error: NSError?) -> Void in
            if let error = error {
                var errorMessage = "Failed to retrieve items. \(error.localizedDescription)"
                if (error.domain == AWSServiceErrorDomain && error.code == AWSServiceErrorType.accessDeniedException.rawValue) {
                    errorMessage = "Access denied. You are not allowed to perform this operation."
                }
            }
            else if response!.items.count == 0 {
                self.showSimpleAlertWithTitle("Not Found", message: "No items match your criteria. Insert more sample data and try again.", cancelButtonTitle: "OK")
            }
            else {
                if self.refresh {
                    os_log("refresh called", log: OSLog.default, type: .debug)
                    if response!.items.count != self.workouts[self.selected]?.count {
                        DispatchQueue.main.async {
                            self.loadMoreContents()
                            
                            self.refresh = false
                        }
                        self.formatVideoDetails(response)
                    }
                } else {
                    self.formatVideoDetails(response)
                }
            }
            
            self.updateUserInterface()
        }
        
        os_log("loading videoDetails content", log: OSLog.default, type: .debug)
        if !self.loadedDetails[self.selected]! {
            DispatchQueue.main.async {
                self.getVideoDetailsByType(completionHandler)
            }
        }
        os_log("after loading videoDetails content", log: OSLog.default, type: .debug)
    }
    
    func formatVideoDetails(_ response: AWSDynamoDBPaginatedOutput?) {
        // put data into correct spot
        let response = response?.items as! [Workouts]
        var vidArray = [WorkoutVids]()
        var key: String?
        for item in response {
            key = self.prefix + item._workoutName! + ".mp4"
            let workoutVid = WorkoutVids()
            workoutVid.name = item._workoutName
            workoutVid.description = item._videoDescription
            workoutVid.length = item._videoLength
            if let awsContents = self.contents {
                if let i = awsContents.index(where: { $0.key == key }) {
                    workoutVid.content = awsContents[i]
                }
            }
            vidArray.append(workoutVid)
        }
        self.workouts[self.selected] = vidArray
        self.loadedDetails[self.selected] = true
    }
    
    
    
    func getVideoDetailsByType(_ completionHandler: @escaping (_ response: AWSDynamoDBPaginatedOutput?, _ error: NSError?) -> Void) {
        let objectMapper = AWSDynamoDBObjectMapper.default()
        let queryExpression = AWSDynamoDBQueryExpression()
        
        queryExpression.indexName = "workoutTypeIndex"
        queryExpression.keyConditionExpression = "#workoutType = :workoutType"
        queryExpression.expressionAttributeNames = ["#workoutType": "WorkoutType",]
        queryExpression.expressionAttributeValues = [":workoutType": selected,]
        
        objectMapper.query(Workouts.self, expression: queryExpression) { (response: AWSDynamoDBPaginatedOutput?, error: Error?) in
            DispatchQueue.main.async(execute: {
                completionHandler(response, error as NSError?)
            })
        }
    }
    
    // MARK:- Content user action methods
    
    fileprivate func showActionOptionsForContent(_ rect: CGRect, content: AWSContent) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if alertController.popoverPresentationController != nil {
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = CGRect(x: rect.midX, y: rect.midY, width: 1.0, height: 1.0)
        }
        if content.isCached {
            let openAction = UIAlertAction(title: "Open", style: .default, handler: {(action: UIAlertAction) -> Void in
                DispatchQueue.main.async {
                    self.openContent(content)
                }
            })
            alertController.addAction(openAction)
        }
        
        // Allow opening of remote files natively or in browser based on their type.
        let openRemoteAction = UIAlertAction(title: "Open Remote", style: .default, handler: {[unowned self](action: UIAlertAction) -> Void in
            self.openRemoteContent(content)
            
        })
        alertController.addAction(openRemoteAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func openContent(_ content: AWSContent) {
        if content.isAudioVideo() { // Video and sound files
            let directories: [AnyObject] = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [AnyObject]
            let cacheDirectoryPath = directories.first as! String
            
            let movieURL: URL = URL(fileURLWithPath: "\(cacheDirectoryPath)/\(content.key.getLastPathComponent())")
            
            try? content.cachedData.write(to: movieURL, options: [.atomic])
            
            let player = AVPlayer(url: movieURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                playerViewController.player!.play()
            }
        } else {
            showSimpleAlertWithTitle("Sorry!", message: "We can only open video, and sound files.", cancelButtonTitle: "OK")
        }
    }
    
    fileprivate func openRemoteContent(_ content: AWSContent) {
        content.getRemoteFileURL {[weak self] (url: URL?, error: Error?) in
            guard let strongSelf = self else { return }
            guard let url = url else {
                print("Error getting URL for file. \(String(describing: error))")
                return
            }
            if content.isAudioVideo() { // Open Audio and Video files natively in app.
                let player = AVPlayer(url: url)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                strongSelf.present(playerViewController, animated: true) {
                    playerViewController.player!.play()
                }
                /*
                let controller: MPMoviePlayerViewController = MPMoviePlayerViewController(contentURL: url)
                controller.moviePlayer.prepareToPlay()
                controller.moviePlayer.play()
                strongSelf.presentMoviePlayerViewControllerAnimated(controller)
                 */
            } else { // Open other file types like PDF in web browser.
                
            }
        }
    }
    
    // MARK:- Content uploads
    
    fileprivate func showImagePicker() {
        let imagePickerController: UIImagePickerController = UIImagePickerController()
        imagePickerController.mediaTypes =  [kUTTypeMovie as String]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func setIcons() {
        // create tapGestureRecognizer for images
        let tapArmWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleArmWorkouts))
        let tapLegWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleLegWorkouts))
        let tapCardioBodyWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleCardioWorkouts))
        let tapAbsWorkoutsGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.handleAbsWorkouts))
        
        // Optionally set the number of required taps, e.g., 2 for a double click
        tapArmWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        tapLegWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        tapCardioBodyWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        tapAbsWorkoutsGestureRecognizer.numberOfTapsRequired = 1
        
        
        // Attach it to a view of your choice. If it's a UIImageView, remember to enable user interaction
        armWorkoutsLabel.isUserInteractionEnabled = true
        armWorkoutsLabel.addGestureRecognizer(tapArmWorkoutsGestureRecognizer)
        legWorkoutsLabel.isUserInteractionEnabled = true
        legWorkoutsLabel.addGestureRecognizer(tapLegWorkoutsGestureRecognizer)
        cardioWorkoutsLabel.isUserInteractionEnabled = true
        cardioWorkoutsLabel.addGestureRecognizer(tapCardioBodyWorkoutsGestureRecognizer)
        abWorkoutsLabel.isUserInteractionEnabled = true
        abWorkoutsLabel.addGestureRecognizer(tapAbsWorkoutsGestureRecognizer)
    }
    
    func handleCategories() {
        switch selected {
        case "armVideos":
            os_log("Arm is selected", log: OSLog.default, type: .debug)
            armWorkoutsLabel.backgroundColor = UIColor.lightGray
            loadVideoDetails()
        case "legVideos":
            os_log("Leg is selected", log: OSLog.default, type: .debug)
            legWorkoutsLabel.backgroundColor = UIColor.lightGray
            loadVideoDetails()
        case "cardioVideos":
            os_log("Cardio is selected", log: OSLog.default, type: .debug)
            cardioWorkoutsLabel.backgroundColor = UIColor.lightGray
            loadVideoDetails()
        case "abVideos":
            os_log("Ab is selected", log: OSLog.default, type: .debug)
            abWorkoutsLabel.backgroundColor = UIColor.lightGray
            loadVideoDetails()
        default:
            os_log("This should never be called", log: OSLog.default, type: .debug)
        }
        updateUserInterface()
    }
    
    func resetCategory() {
        switch selected {
            case "armVideos":
                armWorkoutsLabel.backgroundColor = UIColor.white
            case "legVideos":
                legWorkoutsLabel.backgroundColor = UIColor.white
            case "abVideos":
                abWorkoutsLabel.backgroundColor = UIColor.white
            case "cardioVideos":
                cardioWorkoutsLabel.backgroundColor = UIColor.white
            default:
                os_log("This should never be called 2", log: OSLog.default, type: .debug)
        }
    }
    
    func handleArmWorkouts() {
        resetCategory()
        selected = "armVideos"
        handleCategories()
    }
    
    func handleLegWorkouts() {
        resetCategory()
        selected = "legVideos"
        handleCategories()
    }
    
    func handleAbsWorkouts() {
        resetCategory()
        selected = "abVideos"
        handleCategories()
    }
    
    func handleCardioWorkouts() {
        resetCategory()
        selected = "cardioVideos"
        handleCategories()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let workouts = self.workouts[selected] {
            return workouts.count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: WorkoutVideoCell = tableView.dequeueReusableCell(withIdentifier: "WorkoutVideoCell", for: indexPath) as! WorkoutVideoCell

        let workoutvids: [WorkoutVids] = workouts[selected]!
        let workout: WorkoutVids = workoutvids[indexPath.row]
        cell.prefix = prefix
        cell.content = workout
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layer.shadowOpacity = 1.0
        cell.layer.shadowRadius = 1
        cell.layer.shadowOffset = CGSize(width: 0, height: 2)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowPath = UIBezierPath(rect: cell.bounds).cgPath
        cell.layer.masksToBounds = false
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 125.0;//Choose your custom row height
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let content = contents![indexPath.row]
        let rowRect = tableView.rectForRow(at: indexPath);
        showActionOptionsForContent(rowRect, content: content)
    }
}

// MARK:- UIImagePickerControllerDelegate

extension WorkoutsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        dismiss(animated: true, completion: nil)
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        // Handle Video Uploads
        if mediaType.isEqual(to: kUTTypeMovie as String) {
            let videoURL: URL = info[UIImagePickerControllerMediaURL] as! URL
            
            
            let storyboard = UIStoryboard(name: "Workouts", bundle: nil)
            let uploadWorkoutsViewController = storyboard.instantiateViewController(withIdentifier: "UploadWorkouts") as! UploadWorkoutsViewController
            uploadWorkoutsViewController.data = try! Data(contentsOf: videoURL)
            uploadWorkoutsViewController.url = videoURL
            uploadWorkoutsViewController.manager = self.manager
            self.navigationController!.pushViewController(uploadWorkoutsViewController, animated: true)
            
            //askForFilename(try! Data(contentsOf: videoURL))
            
        }
    }
}

class WorkoutVideoCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var videoLength: UILabel!
    
    //@IBOutlet weak var keepImageView: UIImageView!
    //@IBOutlet weak var downloadedImageView: UIImageView!
    
    var prefix: String?
    
    var content: WorkoutVids! {
        didSet {
            fileNameLabel.text = content.name
            detailLabel.text = content.description
            previewImage.image = content.previewImage
            videoLength.text = content.length
        }
    }
}

class UserFilesUploadCell: UITableViewCell {
    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var prefix: String?
    
    var localContent: AWSLocalContent! {
        didSet {
            var displayFilename: String = localContent.key
            displayFilename = displayFilename.replacingOccurrences(of: AWSIdentityManager.default().identityId!, with: "<private>")
            fileNameLabel.text = displayFilename
            progressView.progress = Float(localContent.progress.fractionCompleted)
        }
    }
}

// MARK: - Utility

extension WorkoutsViewController {
    fileprivate func showSimpleAlertWithTitle(_ title: String, message: String, cancelButtonTitle cancelTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension AWSContent {
    fileprivate func isAudioVideo() -> Bool {
        let lowerCaseKey = self.key.lowercased()
        return lowerCaseKey.hasSuffix(".mov")
            || lowerCaseKey.hasSuffix(".mp4")
            || lowerCaseKey.hasSuffix(".mpv")
            || lowerCaseKey.hasSuffix(".3gp")
            || lowerCaseKey.hasSuffix(".mpeg")
            || lowerCaseKey.hasSuffix(".aac")
            || lowerCaseKey.hasSuffix(".mp3")
    }
    
    fileprivate func isImage() -> Bool {
        let lowerCaseKey = self.key.lowercased()
        return lowerCaseKey.hasSuffix(".jpg")
            || lowerCaseKey.hasSuffix(".png")
            || lowerCaseKey.hasSuffix(".jpeg")
    }
}

extension UInt {
    fileprivate func aws_stringFromByteCount() -> String {
        if self < 1024 {
            return "\(self) B"
        }
        if self < 1024 * 1024 {
            return "\(self / 1024) KB"
        }
        if self < 1024 * 1024 * 1024 {
            return "\(self / 1024 / 1024) MB"
        }
        return "\(self / 1024 / 1024 / 1024) GB"
    }
}

extension String {
    fileprivate func getLastPathComponent() -> String {
        let nsstringValue: NSString = self as NSString
        return nsstringValue.lastPathComponent
    }
}
