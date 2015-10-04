//
//  ViewController.swift
//  FatCheck
//
//  Created by Viktor Vojnovski on 04.10.15.
//  Copyright © 2015 Viktor Vojnovski. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: Constants
    let ctxtDown: Int = 20
    let ctxtUp: Int = 20
    let healthStore = HKHealthStore()
    let weightType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
    
    // MARK: Data
    var pickerData: [String] = [String]()
    var weight = 100.0
    var timeSince = 0.0
    
    // MARK: Properties
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var saveButton: UIButton!
 
    // MARK: View Logic
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.dataSource = self;
        pickerView.delegate = self;
        
        // Initialize and ask for authorisation
        doHealthKitManagement()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appToForground" , name:UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Read current weight and populate picker
        readMostRecentSample(weightType!, completion: manageModelUpdate)
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func appToForground() {
        readMostRecentSample(weightType!, completion: manageModelUpdate)
    }
    
    // MARK: UIPickerView logic
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count;
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    // MARK: Actions
    @IBAction func saveWeight(sender: UIButton) {
        let newweight = pickerData[pickerView.selectedRowInComponent(0)]
        setNewModel(newweight, timeSince: timeSince)
    }

    // MARK: Private functions
    // Todo: Lazy initialize healthStore depending on platform and check for presence
    private func doHealthKitManagement() {
        if let weightType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) {
            let setType = Set<HKSampleType>(arrayLiteral: weightType)
            healthStore.requestAuthorizationToShareTypes(setType, readTypes: setType, completion: { (success, error) -> Void in
                // Todo: Exit app on error
            })
        }
    }
    
    // Function to pass to the HealthKitReader
    private func manageModelUpdate(weights:[HKSample]!, error:NSError!) {
        if( error != nil )
        {
            print("Error reading weight from HealthKit Store: \(error.localizedDescription)")
            return;
        }
        
        if let result = weights {
            // Get the first result
            if let item = result.first {
                let sample = item as? HKQuantitySample
                let kilograms = sample!.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
                let timeSince = NSDate().timeIntervalSinceDate(sample!.startDate)
                setNewModel("\(kilograms)", timeSince: timeSince)
            }
        }
    }
    
    // Updates datamodel (self.weight) and propagates changes to the picker View
    private func setNewModel(weight: String, timeSince: Double) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.weight = Double(weight)!
            self.timeSince = timeSince
            print(timeSince)
            self.topLabel.text = weight
            // Stupid swift not recognizing map as it should
            self.pickerData.removeAll()
            for i in (-self.ctxtDown...self.ctxtUp) {
                self.pickerData.append("\(Double(weight)! + Double(i) * 0.1)")
            }
            self.pickerView.reloadAllComponents()
            self.pickerView.selectRow(self.ctxtDown, inComponent: 0, animated: true)
            if timeSince < 300 {
                self.saveButton.enabled = false
                self.pickerView.userInteractionEnabled = false
                // Add a label that explains this
                // Start a counter that re-enables everything after a while
            }
        });
    }

    // MARK: HealthKit Helpers
    // Todo: Put this in a Factory class?
    private func readMostRecentSample(sampleType:HKSampleType, completion: (([HKSample]!, NSError!) -> Void)!) {
        // startDate and endDate are NSDate objects
        let startDate = NSDate.distantPast()
        let endDate   = NSDate()
        
        // we create a predicate to filter our data
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate,endDate: endDate ,options: .None)
        
        // I had a sortDescriptor to get the recent data first
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // we create our query with a block completion to execute
        let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 30, sortDescriptors: [sortDescriptor]) { (query, tmpResult, error) -> Void in
            
            if error != nil {
                return
            }
            
            if completion != nil {
                completion(tmpResult,nil)
            }
        }
        
        // finally, we execute our query
        healthStore.executeQuery(query)
    }
    
}

