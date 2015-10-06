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
    let timeout: Double = 300
    let ctxtDown: Int = 20
    let ctxtUp: Int = 20
    let healthStore = HKHealthStore()
    let weightType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
    
    // MARK: Data
    var pickerData: [String] = [String]()
    var weight = 100.0
    var timeSince = 0.0
    
    // MARK: Properties
    @IBOutlet weak var topView: BorderedView!
    @IBOutlet weak var dataView: UIView!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var buttonView: BorderedView!

    
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var warningLabel: UILabel!
    
    // MARK: View Logic
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerView.dataSource = self;
        pickerView.delegate = self;
        
        //Do borders and change button form to circle
        doUIStuff()
        
        // Initialize and ask for authorisation
        doHealthKitManagement()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "appToForeground" , name:UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Read current weight and populate picker
        readMostRecentSample(weightType!, completion: manageModelUpdate)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func appToForeground() {
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
        let newweight = String(pickerData[pickerView.selectedRowInComponent(0)].characters.dropLast().dropLast().dropLast())
        writeMostRecentSample(newweight)
        readMostRecentSample(weightType!, completion: manageModelUpdate)
    }

    // MARK: Private functions
    private func doUIStuff() {
        buttonView.borderWidth=CGFloat(1.0)
        buttonView.borderDrawOptions = BorderedViewDrawOptions.DrawTop
        topView.borderWidth=CGFloat(1.0)
        topView.borderDrawOptions = BorderedViewDrawOptions.DrawBottom
        saveButton.layer.cornerRadius = saveButton.frame.width/2.0
    }
    
    private func doHealthKitManagement() {
        
        if !HKHealthStore.isHealthDataAvailable()
        {
            let error = NSError(domain: "mk.vv.FatCheck", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available on this Device"])
            print("\(error.localizedDescription)")
            return;
        }
        
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
            // Todo: Manage error where no results (Either never used, or no access given)
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
            // Stupid swift not recognizing map as it should
            self.pickerData.removeAll()
            for i in (-self.ctxtDown...self.ctxtUp) {
                self.pickerData.append("\(Double(weight)! + Double(i) * 0.1) kg")
            }
            self.pickerView.reloadAllComponents()
            self.pickerView.selectRow(self.ctxtDown, inComponent: 0, animated: true)
            if timeSince < self.timeout {
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
    
    private func writeMostRecentSample(newweight: String) {
        let startDate = NSDate()
        let newvalue = Double(newweight)!
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnitWithMetricPrefix(.Kilo), doubleValue: newvalue)
        let object = HKQuantitySample(type: weightType!, quantity: weightQuantity, startDate: startDate, endDate: startDate)
        healthStore.saveObject(object, withCompletion: { (success, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if error != nil {
                    print("Error reading weight from HealthKit Store: \(error!.localizedDescription)")
                    // Todo: App crashes if no authorisation given
                    return
                }
                if success {
                    print("Data \(weightQuantity) saved to HK.")
                } else {
                    print("Data not saved correctly.")
                }
            })
        })
    }
}

