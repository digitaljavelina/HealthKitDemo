//
//  HealthManager.swift
//  HKTutorial
//
//  Created by ernesto on 18/10/14.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import Foundation
import HealthKit

class HealthManager {
  
  let healthKitStore:HKHealthStore = HKHealthStore()
  
  func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!) {
    //set the types you want to read from the HKStore
    let healthKitTypesToRead = NSSet(array:[
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth),
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType),
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight),
      HKObjectType.workoutType()
    ])
    
    //set the types you want to write to HKStore
    let healthKitTypesToWrite = NSSet(array:[
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning),
      HKQuantityType.workoutType()
      ])
    
    //If the store is not available (for instance, iPad) return an error and don't go on.
    if (!HKHealthStore.isHealthDataAvailable()) {
    
    let error = NSError(domain: "com.raywenderlich.tutorials.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available in this device."])
    if(completion != nil) {
      completion(success: false, error: error)
    }
    
    return
    
  }
  
  //Request HealthKit authorization
  healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToWrite, readTypes: healthKitTypesToRead) {
    (success, error) -> Void in
  
    if (completion != nil) {
  completion(success: success, error: error)
  
      }
    }
  }
  
  func readProfile() -> (age: Int?, biologicalSex: HKBiologicalSexObject?, bloodType: HKBloodTypeObject?) {
    var error: NSError?
    var age: Int?
    
    //Request birthday and calculate age
    if let birthDay = healthKitStore.dateOfBirthWithError(&error) {
      let today = NSDate()
      let calendar = NSCalendar.currentCalendar()
      let differenceComponents = NSCalendar.currentCalendar().components(.YearCalendarUnit, fromDate: birthDay, toDate: today, options: NSCalendarOptions(0))
      age = differenceComponents.year
    }
    
    if error != nil {
      println("Error reading birthday: \(error)")
    }
    
    //Read biological sex
    var biologicalSex:HKBiologicalSexObject? = healthKitStore.biologicalSexWithError(&error)
    if error != nil {
      println("Error reading biological sex: \(error)")
    }
    
    //Read blood type
    var bloodType:HKBloodTypeObject? = healthKitStore.bloodTypeWithError(&error)
    if error != nil {
      println("Error reading blood type: \(error)")
    }
    
    //Return the information read in a tuple
    return (age, biologicalSex, bloodType)
  }
  
  func readMostRecentSample(sampleType: HKSampleType, completion: ((HKSample!, NSError!) -> Void)!) {
    //Build the predicate
    let past = NSDate.distantPast() as NSDate
    let now = NSDate()
    let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate: now, options: .None)
    
    //Build the sort descriptor to return the samples in descending order
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    
    //We want to limit the number of samples returned by the query to just 1 (most recent)
    let limit = 1
    
    //Build sample query
    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error) -> Void in
      
      if let queryError = error {
        completion(nil, error)
        return
      }
      
      //Get the first sample
      let mostRecentSample = results.first as? HKQuantitySample
      
      //Execute the completion closure
      if completion != nil {
        completion(mostRecentSample, nil)
      }
    }
    
    //Execute the query
    self.healthKitStore.executeQuery(sampleQuery)
  }
  
  func saveBMISample (bmi:Double, date: NSDate) {
    //Create a BMI sample
    let bmiType = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex)
    let bmiQuantity = HKQuantity(unit: HKUnit.countUnit(), doubleValue: bmi)
    let bmiSample = HKQuantitySample(type: bmiType, quantity: bmiQuantity, startDate: date, endDate: date)
    
    //Save the sample in the store
    healthKitStore.saveObject(bmiSample, withCompletion: { (success, error) -> Void in
      if (error != nil) {
        println("Error saving BMI sample: \(error.localizedDescription)")
      } else {
        println("BMI sample saved successfully")
      }
    })
    
  }
  
  func saveRunningWorkout (startDate: NSDate, endDate: NSDate, distance: Double, distanceunit: HKUnit, kiloCalories: Double, completion: ( (Bool, NSError!) -> Void)!) {
    
    //Create quantities for distance and energy burned
    let distanceQuantity = HKQuantity(unit: distanceunit, doubleValue: distance)
    let caloriesQuantity = HKQuantity(unit: HKUnit.kilocalorieUnit(), doubleValue: kiloCalories)
    
    //Save running workout
    let workout = HKWorkout(activityType: HKWorkoutActivityType.Running, startDate: startDate, endDate: endDate, duration: abs(endDate.timeIntervalSinceDate(startDate)), totalEnergyBurned: caloriesQuantity, totalDistance: distanceQuantity, metadata: nil)
    healthKitStore.saveObject(workout, withCompletion: { (success, error) -> Void in
      if (error != nil) {
        //Error saving the workout
        completion(success, error)
      } else {
        //if success, save the associated samples so that they appear in the HealthKit
        let distanceSample = HKQuantitySample(type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning), quantity: distanceQuantity, startDate: startDate, endDate: endDate)
        let caloriesSample = HKQuantitySample(type: HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned), quantity: caloriesQuantity, startDate: startDate, endDate: endDate)
        
        self.healthKitStore.addSamples([distanceSample, caloriesSample], toWorkout: workout, completion: { (success, error) -> Void in
          completion(success, error)
        })
      }
    })
  }
  
  func readRunningWorkOuts(completion: (([AnyObject], NSError!) -> Void)!) {
    //Build the predicate
    let predicate = HKQuery.predicateForWorkoutsWithWorkoutActivityType(HKWorkoutActivityType.Running)
    //Order the workouts by date
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
    
    //Build sample query
    let sampleQuery = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error) -> Void in
      if let queryError = error {
        println("There was an error while reading the samples: \(queryError.localizedDescription)")
      }
      
     completion(results, error)
    }
    
    //Execute the query
    self.healthKitStore.executeQuery(sampleQuery)
    
  }
}
  
