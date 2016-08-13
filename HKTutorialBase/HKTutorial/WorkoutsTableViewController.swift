//
//  WorkoutsTableViewController.swift
//  HKTutorial
//
//  Created by ernesto on 18/10/14.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import UIKit
import HealthKit


public enum DistanceUnit:Int {
  case Miles=0, Kilometers=1
}

public class WorkoutsTableViewController: UITableViewController {
  
  let kAddWorkoutReturnOKSegue = "addWorkoutOKSegue"
  let kAddWorkoutSegue  = "addWorkoutSegue"
  
  var distanceUnit = DistanceUnit.Miles
  var healthManager:HealthManager?
  var workouts = [HKWorkout]()
  
  // MARK: - Formatters
  lazy var dateFormatter:NSDateFormatter = {
    
    let formatter = NSDateFormatter()
    formatter.timeStyle = .ShortStyle
    formatter.dateStyle = .MediumStyle
    return formatter;
    
    }()
  
  let durationFormatter = NSDateComponentsFormatter()
  let energyFormatter = NSEnergyFormatter()
  let distanceFormatter = NSLengthFormatter()
  
  // MARK: - Class Implementation
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    
    self.clearsSelectionOnViewWillAppear = false
    
  }
  
  public override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    
  }
  
  public override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
    if( segue.identifier == kAddWorkoutSegue )
    {
      
      if let addViewController:AddWorkoutTableViewController = segue.destinationViewController.topViewController as? AddWorkoutTableViewController {
        addViewController.distanceUnit = distanceUnit
      }
    }
    
  }
  
  @IBAction func unitsChanged(sender:UISegmentedControl) {
    
    distanceUnit  = DistanceUnit(rawValue: sender.selectedSegmentIndex)!
    tableView.reloadData()
    
  }
  
  public override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    healthManager?.readRunningWorkOuts({ (results, error) -> Void in
      if (error != nil) {
        println("Error reading workouts: \(error.localizedDescription)")
        return
      } else {
       println("Workouts read successfully")
      }
      
      //Keep workouts and refresh table view in main thread
      self.workouts = results as [HKWorkout]
      dispatch_async(dispatch_get_main_queue(), { () -> Void in
        self.tableView.reloadData()
      })
    })
  }
  
  public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return workouts.count
  }
  
  public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("workoutcellid", forIndexPath: indexPath) as UITableViewCell
    
    //Get workout for the row. Cell text: workout date
    let workout = workouts[indexPath.row]
    let startDate = dateFormatter.stringFromDate(workout.startDate)
    cell.textLabel!.text = startDate
    
    //Detail text: Duration - Distance
    //Duration
    var detailText = "Duration: " + durationFormatter.stringFromTimeInterval(workout.duration)!
    //Distance in Km or miles depending on user selection
    detailText += " Distance: "
    if (distanceUnit == .Kilometers) {
      let distanceInKM = workout.totalDistance.doubleValueForUnit(HKUnit.meterUnitWithMetricPrefix(HKMetricPrefix.Kilo))
      detailText += distanceFormatter.stringFromValue(distanceInKM, unit: NSLengthFormatterUnit.Kilometer)
    } else {
      let distanceInMiles = workout.totalDistance.doubleValueForUnit(HKUnit.mileUnit())
      detailText += distanceFormatter.stringFromValue(distanceInMiles, unit: NSLengthFormatterUnit.Mile)
    }
    
    //Detail text: energy burned
    let energyBurned = workout.totalEnergyBurned.doubleValueForUnit(HKUnit.jouleUnit())
    detailText += " Energy: " + energyFormatter.stringFromJoules(energyBurned)
    cell.detailTextLabel?.text = detailText
    
    return cell
  }
  
  // MARK: - Segues
  @IBAction func unwindToSegue (segue : UIStoryboardSegue) {
    
    if( segue.identifier == kAddWorkoutReturnOKSegue ) {
      if let addViewController:AddWorkoutTableViewController = segue.sourceViewController as? AddWorkoutTableViewController {
        
        //Set the unit type
        var hkUnit = HKUnit.meterUnitWithMetricPrefix(.Kilo)
        if distanceUnit == .Miles {
          hkUnit = HKUnit.mileUnit()
        }
        
        //Save the workout
        self.healthManager?.saveRunningWorkout(addViewController.startDate!, endDate: addViewController.endDate!, distance: addViewController.distance, distanceunit: hkUnit, kiloCalories: addViewController.energyBurned!, completion: { (success, error) -> Void in
          if (success) {
            println("Workout saved")
          } else if (error != nil) {
            println("\(error)")
          }
        })
      }
      
    }
    
  }
  
}