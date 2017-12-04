//
//  ViewController.swift
//  Wehter
//
//  Created by yobbo_wang on 17/11/30.
//  Copyright © 2017年 yobbo_wang. All rights reserved.
//

import UIKit
import CoreLocation
import AFNetworking

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManger:CLLocationManager = CLLocationManager() //定义常量
    
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var loaded: UILabel!
    @IBOutlet weak var loadIcon: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //获取当月的时间，动态改变背景图片
        let month = NSCalendar.currentCalendar().components([.Year,.Month,.Day], fromDate: NSDate()).month
        var backImg: String;
        switch month {
        case 1,2,9,10,11,12:
            backImg = "background.png"
        default:
            backImg = "background_summer.png"
        }
        let background = UIImage(named: backImg)
        self.view.backgroundColor = UIColor(patternImage: background!) // 设置背景图片
        //设置正在加载动画
        self.loadIcon.startAnimating()
        locationManger.delegate = self
        locationManger.desiredAccuracy = kCLLocationAccuracyBest //初始化
        if(self.ios8()){
            locationManger.requestAlwaysAuthorization()
        }
        locationManger.startUpdatingLocation()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    //判断iOS版本是否是8.0以上
    func ios8() -> Bool{
        let version_: Float? = Float(UIDevice.currentDevice().systemVersion)
        if let version_ = version_ where version_ > 8.0 {
            print("ios版本为：\(version_)")
            return true
        }
        return false
    }
    
    //更新天气图标
    func updateWeatherIcon(condition: Int, nightTime: Bool){
        if condition < 300 {
            nightTime ? (self.icon.image = UIImage(named: "tstorm1_night")) : (self.icon.image = UIImage(named: "tstorm1"))
        }
        else if condition < 500 {
            self.icon.image = UIImage(named: "light_rain")
        }
        else if condition < 600 {
            self.icon.image = UIImage(named: "shower3")
        }
        else if condition < 700 {
            self.icon.image = UIImage(named: "snow4")
        }
        else if condition < 771 {
            nightTime ? (self.icon.image = UIImage(named: "fog_night")) : (self.icon.image = UIImage(named: "fog"))
        }
        else if condition < 800 {
            self.icon.image = UIImage(named: "tstorm3")
        }
        else if condition == 800 {
            nightTime ? (self.icon.image = UIImage(named: "sunny_night")) : (self.icon.image = UIImage(named: "sunny"))
        }
        else if condition < 804 {
            nightTime ? (self.icon.image = UIImage(named: "cloudy2_night")) : (self.icon.image = UIImage(named: "cloudy2"))
        }
        else if condition == 804 {
            self.icon.image = UIImage(named: "overcast")
        }
        else if (condition >= 900 && condition < 903) || (condition > 904 && condition < 1000) {
            self.icon.image = UIImage(named: "tstorm3")
        }
        else if condition == 903 {
            self.icon.image = UIImage(named: "snow5")
        }
        else if condition == 904 {
            self.icon.image = UIImage(named: "sunny")
        }
        else {
            self.icon.image = UIImage(named: "dunno")
        }
        //113.849333,22.621327
    }
    
    //获取信息成功，更新UI界面
    func updateUISuccess(jsonResult: NSDictionary){
        if let tempResult = jsonResult["main"]?["temp"] as? Double {
            var temperature: Double
            if jsonResult["sys"]?["country"] as! String == "US" {
                temperature = round(((tempResult - 273.15) * 1.8) + 32)
            }
            else {
                temperature = round(tempResult - 273.15)
            }
            //去掉loading信息
            self.loaded.removeFromSuperview(); //从view中移除组件
            self.loadIcon.removeFromSuperview(); //移除
            
            self.temperature.text = "\(temperature)°"
            
            let name = jsonResult["name"] as! String
            self.locationName.text = "\(name)";
            
            let condition: Int = (jsonResult["weather"] as! NSArray)[0]["id"] as! Int
            let sunrise: Double = jsonResult["sys"]?["sunrise"] as! Double
            let sunset: Double = jsonResult["sys"]?["sunset"] as! Double
            var nightTime: Bool = false
            let now: Double = NSDate().timeIntervalSince1970
            
            if now < sunrise || now > sunset {
                nightTime = true
            }
            self.updateWeatherIcon(condition, nightTime: nightTime)
        }
        else {
            self.loaded.text = "获取天气信息异常";
            self.loadIcon.removeFromSuperview(); //移除
        }
    }
    
    //更新天气信息
    func updateWeatherInfo(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let manager = AFHTTPRequestOperationManager();
        let url: String = "http://api.openweathermap.org/data/2.5/weather";
        let params = ["lat": latitude, "lon": longitude, "cnt": 0, "appid": "ade04f6c6e2b3c4123ad29b9f541fb71"];
        manager.GET(url, parameters: params,
            success: {
                (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
//                print("JSON: \(responseObject.description!)")
                self.updateUISuccess(responseObject as! NSDictionary!);
                
            }, failure: {
                (operation: AFHTTPRequestOperation?, error: NSError!) in
//                print("JSON: \(error.localizedDescription)")
                self.loaded.text = "获取天气信息异常";
                self.loadIcon.removeFromSuperview(); //移除
        })
    }
    
    //获取地理位置信息后回调
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations[locations.count - 1] as CLLocation  // as 转换为CLLocation类型
        if(location.horizontalAccuracy > 0){
            print(location.coordinate.latitude)
            print(location.coordinate.longitude)
            self.updateWeatherInfo(location.coordinate.latitude, longitude: location.coordinate.longitude);
            locationManger.stopUpdatingLocation()
        }
    }
    
    //遇到异常错误后回调
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError){
        print(error)
    }
}

