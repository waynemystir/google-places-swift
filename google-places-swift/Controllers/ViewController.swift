//
//  ViewController.swift
//  google-places-swift
//
//  Created by WAYNE SMALL on 11/6/15.
//  Copyright © 2015 Waynemystir. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate, LoadGoogleDataDelegate, UITableViewDataSource, UITableViewDelegate {
    
    private static let cellReuseIdentifier = "cellIdentifier";
    private static let kAutoCompleteMinimumNumberOfCharacters = 4;
    
    // MARK: Outlets

    @IBOutlet weak private var whereToTextField: UITextField!
    @IBOutlet weak private var autoCompleteSpinner: UIActivityIndicatorView!
    @IBOutlet weak private var mapView: MKMapView!
    @IBOutlet weak private var placesTableView: UITableView!
    @IBOutlet weak private var placesTvBottomConstr: NSLayoutConstraint!
    
    // MARK: Stored Properties
    
    private let locationMgr: CLLocationManager
    private var zoomLocation: CLLocationCoordinate2D {
        let sp = Places.manager.selectedPlace
        return CLLocationCoordinate2DMake(sp.latitude!, sp.longitude!)
    }
    private var placesTableData: [GooglePlace]
    private var placeTvTopMinusSuperVwBottom: CGFloat {
        return UIScreen.mainScreen().bounds.size.height - self.placesTableView.frame.origin.y
    }
    private var openTasks: [NSURLSessionTask]
    
    // MARK: Lifecycle
    
    required init() {
        locationMgr = CLLocationManager()
        placesTableData = []
        openTasks = []
        super.init(nibName: "View", bundle: nil)
        LoadGoogleData.manager.googleDelegate = self
        locationMgr.distanceFilter = kCLDistanceFilterNone
        locationMgr.desiredAccuracy = kCLLocationAccuracyKilometer
        locationMgr.delegate = self
        if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse { locationMgr.requestWhenInUseAuthorization() }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = true
        self.mapView.delegate = self
        self.whereToTextField.delegate = self
        self.autoCompleteSpinner.stopAnimating()
        self.autoCompleteSpinner.hidden = true
        self.placesTvBottomConstr.constant = self.placeTvTopMinusSuperVwBottom        
        self.placesTableView.tableHeaderView = nil
        self.placesTableView.dataSource = self
        self.placesTableView.delegate = self
        self.placesTableView.registerNib(UINib(nibName: "PlaceTableViewCell", bundle: nil), forCellReuseIdentifier: ViewController.cellReuseIdentifier)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "animateOpenPlacesTblVw:", name: UIKeyboardWillShowNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        self.mapView.showsUserLocation = (CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse)
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        if let loc = userLocation.location {
            Places.manager.savedPlaces[0].latitude = loc.coordinate.latitude;
            Places.manager.savedPlaces[0].longitude = loc.coordinate.longitude;
            
            if Places.manager.currentLocationIsSelectedPlace {
                self.redrawMapView(true, radius: Places.manager.savedPlaces[0].zoomRadius ?? 3.0)
            }
        }
    }
    
    // MARK: UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.whereToTextField.text = ""
        self.showSavedPlacesInTblView()
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        self.quitTasksAndSpinners()
        if let tft = textField.text {
            let autoCompleteText = (tft as NSString).stringByReplacingCharactersInRange(range, withString: string)
            if autoCompleteText.characters.count >= ViewController.kAutoCompleteMinimumNumberOfCharacters {
                if self.placesTableData == Places.manager.savedPlaces {
                    self.placesTableData = []
                    self.placesTableView.reloadData()
                }
                self.openTasks.append(LoadGoogleData.autocomplete(autoCompleteText))
                self.autoCompleteSpinner.hidden = false
                self.autoCompleteSpinner.startAnimating()
            }
        } else {
            self.textFieldShouldClear(textField)
        }
        
        return true;
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        self.quitTasksAndSpinners()
        self.showSavedPlacesInTblView()
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if self.placesTableData == Places.manager.savedPlaces {
            self.whereToTextField.text = Places.manager.selectedPlace.placeDescription
        } else if self.placesTableData.count > 0 {
            let gp = self.placesTableData[0]
            LoadGoogleData.loadPlaceDetails(gp.placeId)
            self.whereToTextField.text = gp.placeDescription
        }
        textField.resignFirstResponder()
        return true;
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.animateClosePlacesTblVw()
    }
    
    // MARK: LoadGoogleDataDelegate
    
    func loadedData(dataType: GOOGLE_DATA, googleObject: NetworkResponseDelegate) {
        switch(dataType) {
        case .AUTOCOMPLETE:
            self.autoCompleteSpinner.stopAnimating()
            self.autoCompleteSpinner.hidden = true
            self.placesTableData = googleObject.responseRecords as! [GooglePlaceAutocomplete];
            self.placesTableView.reloadData()
            
        case .PLACE_DETAILS:
            self.resetSelectedPlace(googleObject as! GooglePlaceDetails)
        }
    }
    
    func requestTimedOut(dataType: GOOGLE_DATA) {
        self.alertToFailure("Request Timed Out", message: "The request timed out")
    }
    
    func requestFailedOffline(dataType: GOOGLE_DATA) {
        self.alertToFailure("No network connection", message: "Please check your connection and try again")
    }
    
    func requestFailed(dataType: GOOGLE_DATA) {
        self.alertToFailure("Request Failed", message: "Please try again later")
    }
    
    func alertToFailure(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
        self.presentViewController(ac, animated: true, completion: nil)
        self.quitTasksAndSpinners()
    }

    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.placesTableData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ViewController.cellReuseIdentifier) as! PlaceTableViewCell
        let place = self.placesTableData[indexPath.row]
        cell.placeDescription.text = place.placeDescription
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.5
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let topSeparator = UIView(frame: CGRectMake(0, 0, 320, 0.5))
        topSeparator.backgroundColor = AppEnvironment.UIColorFromRGB(0xbbbbbb)
        self.placesTableView.addSubview(topSeparator)
        return topSeparator
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let gp = self.placesTableData[indexPath.row]
        if gp is GooglePlaceDetails { self.resetSelectedPlace(gp as! GooglePlaceDetails) }
        else if gp is GooglePlaceAutocomplete { LoadGoogleData.loadPlaceDetails(gp.placeId) }
        self.view.endEditing(true)
    }
    
    // MARK: Various
    
    func quitTasksAndSpinners() {
        for task in self.openTasks { task.cancel() }
        self.autoCompleteSpinner.stopAnimating()
        self.autoCompleteSpinner.hidden = true
    }
    
    func redrawMapView(animated: Bool, radius: Double) {
        let cr = 1.6 * radius * AppEnvironment.kMetersPerMile
        let viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, cr, cr)
        self.mapView.setRegion(viewRegion, animated: true)
    }
    
    func animateOpenPlacesTblVw(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue else { return }
        self.view.layoutIfNeeded()
        self.placesTvBottomConstr.constant = keyboardFrame.size.height
        UIView.animateWithDuration(0.3) { [unowned self] in self.view.layoutIfNeeded() }
    }
    
    func animateClosePlacesTblVw() {
        self.view.layoutIfNeeded()
        self.placesTvBottomConstr.constant = self.placeTvTopMinusSuperVwBottom
        UIView.animateWithDuration(0.3) { [unowned self] in self.view.layoutIfNeeded() }
    }
    
    func resetSelectedPlace(gp: GooglePlaceDetails) {
        Places.manager.selectedPlace = gp
        self.whereToTextField.text = Places.manager.selectedPlace.placeDescription
        self.redrawMapView(true, radius: Places.manager.selectedPlace.zoomRadius!)
    }
    
    func showSavedPlacesInTblView() {
        if self.placesTableData != Places.manager.savedPlaces {
            self.placesTableData = Places.manager.savedPlaces
            self.placesTableView.reloadData()
        }
    }

}

