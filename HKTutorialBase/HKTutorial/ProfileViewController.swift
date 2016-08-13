//
//  ProfileViewController.swift
//  HKTutorial
//
//  Created by ernesto on 18/10/14.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import UIKit
import HealthKit

class ProfileViewController: UITableViewController {
  
  let UpdateProfileInfoSection = 2
  let SaveBMISection = 3
  let kUnknownString   = "Unknown"
  
  @IBOutlet var ageLabel:UILabel!
  @IBOutlet var bloodTypeLabel:UILabel!
  @IBOutlet var biologicalSexLabel:UILabel!
  @IBOutlet var weightLabel:UILabel!
  @IBOutlet var heightLabel:UILabel!
  @IBOutlet var bmiLabel:UILabel!
  
  var healthManager:HealthManager?
  var bmi:Double?
  var height, weight: HKQuantitySample?
  
  
  
  func updateHealthInfo() {
    
    updateProfileInfo();
    updateWeight();
    updateHeight();
    
  }
  
  func updateProfileInfo() {
    let profile = healthManager?.readProfile()
    
    ageLabel.text = profile?.age == nil ? kUnknownString: String(profile!.age!)
    biologicalSexLabel.text = biologicalSexLiteral(profile?.biologicalSex?.biologicalSex)
    bloodTypeLabel.text = bloodTypeLiteral(profile?.bloodType?.bloodType)
    
  }
  
  
  func updateHeight() {
    //Construct and HKSampleType for height
    let sampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight)
    
    //Call the method to read the most recent height sample
    self.healthManager?.readMostRecentSample(sampleType, completion: { (mostRecentHeight, error) -> Void in
      
      if (error != nil) {
        println("Error reading height from HealthKit Store: \(error.localizedDescription)")
        return
      }
      
      var heightLocalizedString = self.kUnknownString
      
      //Format the height to display it on the screen
      self.height = mostRecentHeight as? HKQuantitySample
      if let meters = self.height?.quantity.doubleValueForUnit(HKUnit.meterUnit()) {
        let heightFormatter = NSLengthFormatter()
        heightFormatter.forPersonHeightUse = true
        heightLocalizedString = heightFormatter.stringFromMeters(meters)
      }
      
      //Update UI in the main thread
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.heightLabel.text = heightLocalizedString
        self.updateBMI()
      })
    })
    
  }
  
  func updateWeight() {
    //Construct an HKSampleType for weight
    let sampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass)
    
    //Call the method to read the most recent weight sample
    self.healthManager?.readMostRecentSample(sampleType, completion: { (mostRecentWeight, error) -> Void in
      
      if (error != nil) {
        println("Error reading weight from HealthKit Store: \(error.localizedDescription)")
        return
      }
      
      var weightLocalizedString = self.kUnknownString
      
      //Format the weight to display it on the screen
      self.weight = mostRecentWeight as? HKQuantitySample
      if let kilograms = self.weight?.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo)) {
        let weightFormatter = NSMassFormatter()
        weightFormatter.forPersonMassUse = true
        weightLocalizedString = weightFormatter.stringFromKilograms(kilograms)
      }
      
      //Update UI in the main thread
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.weightLabel.text = weightLocalizedString
        self.updateBMI()
      })
    })
    
  }
  
  func updateBMI() {
    if (weight != nil && height != nil) {
      //Get the weight and height values from the samples read from healthkit
      let weightInKilograms = weight!.quantity.doubleValueForUnit(HKUnit.gramUnitWithMetricPrefix(.Kilo))
      let heightInMeters = height!.quantity.doubleValueForUnit(HKUnit.meterUnit())
      
      //Call the method to calculate the BMI
      bmi = calculateBMIWithWeightInKilograms(weightInKilograms, heightInMeters: heightInMeters)
    }
    
    //Show the calculated BMI
    var BMIString = kUnknownString
    if bmi != nil {
      bmiLabel.text = NSString(format: "%.02f", bmi!)
    }
    
  }
  
  func saveBMI() {
    //Save BMI value with current BMI value
    if bmi != nil {
      healthManager?.saveBMISample(bmi!, date: NSDate())
    } else {
      println("There are no BMI data to save.")
    }
    
  }
  // MARK: - utility methods
  func calculateBMIWithWeightInKilograms(weightInKilograms:Double, heightInMeters:Double) -> Double?
  {
    if heightInMeters == 0 {
      return nil;
    }
    return (weightInKilograms/(heightInMeters*heightInMeters));
  }
  
  
  func biologicalSexLiteral(biologicalSex:HKBiologicalSex?)->String
  {
    var biologicalSexText = kUnknownString;
    
    if  biologicalSex != nil {
      
      switch( biologicalSex! )
      {
      case .Female:
        biologicalSexText = "Female"
      case .Male:
        biologicalSexText = "Male"
      default:
        break;
      }
      
    }
    return biologicalSexText;
  }
  
  func bloodTypeLiteral(bloodType:HKBloodType?)->String
  {
    
    var bloodTypeText = kUnknownString;
    
    if bloodType != nil {
      
      switch( bloodType! ) {
      case .APositive:
        bloodTypeText = "A+"
      case .ANegative:
        bloodTypeText = "A-"
      case .BPositive:
        bloodTypeText = "B+"
      case .BNegative:
        bloodTypeText = "B-"
      case .ABPositive:
        bloodTypeText = "AB+"
      case .ABNegative:
        bloodTypeText = "AB-"
      case .OPositive:
        bloodTypeText = "O+"
      case .ONegative:
        bloodTypeText = "O-"
      default:
        break;
      }
      
    }
    return bloodTypeText;
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath , animated: true)
    
    switch (indexPath.section, indexPath.row)
    {
    case (UpdateProfileInfoSection,0):
      updateHealthInfo()
    case (SaveBMISection,0):
      saveBMI()
    default:
      break;
    }
    
    
  }
  
}