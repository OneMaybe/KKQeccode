//
//  ViewController.swift
//  KKQeccode
//
//  Created by jensen on 15/8/8.
//  Copyright © 2015年 KellenYang. All rights reserved.
//

import UIKit
//导入音频视频基础库
import AVFoundation

class ViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var labelQR: UILabel!
    //视频捕捉会话
    var session: AVCaptureSession?
    //视频画面预览图
    var videoPreviewLayout: AVCaptureVideoPreviewLayer?
    //自动锁定小方框
    var autolockView: UIView?
    
    @IBOutlet weak var buttonReScan: UIButton!
    //重新扫描
    @IBAction func reScan(sender: UIButton) {
        session?.startRunning()
        buttonReScan.hidden = true
        
    }
    //停止扫描
    func stopScan() {
        session?.stopRunning()
        buttonReScan.hidden = false
        view.bringSubviewToFront(buttonReScan)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonReScan.hidden = true
        
        //初始化视频捕捉会话
        session = AVCaptureSession()
        //指定设备是摄像头
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        //输入
        do {
             let input =  try AVCaptureDeviceInput(device: device)
             session?.addInput(input)
        }
        catch {
            print("无法使用摄像头")
            return
        }
        //输出
        let output = AVCaptureMetadataOutput()
        session?.addOutput(output)
        
        //添加元数据对象输出代理
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue());
        //输出类型
        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeFace]
        
        //视频预览层 与 视频捕捉会话关联
        videoPreviewLayout = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayout?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayout?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayout!)
        
        //启动会话
        session?.startRunning()
        
        view.bringSubviewToFront(labelQR)
        
        //自动锁定框初始化
        autolockView = UIView()
        autolockView?.layer.borderColor = UIColor.redColor().CGColor
        autolockView?.layer.borderWidth = 2
        view.addSubview(autolockView!)
        view.bringSubviewToFront(autolockView!)
    }
    
    //一旦视频捕捉有输出
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        //判断元数据是否有输出
        if metadataObjects == nil || metadataObjects.count == 0 {
            autolockView?.frame = CGRectZero
            labelQR.text = "间谍雷达正在扫描中"
            return
        }
        //如果是人脸 （first只有一项）
        if let kkobject = metadataObjects.first as? AVMetadataFaceObject{
            if kkobject.type == AVMetadataObjectTypeFace {
                let faceObject = videoPreviewLayout?.transformedMetadataObjectForMetadataObject(kkobject) as! AVMetadataFaceObject
                autolockView?.frame = faceObject.bounds
                
                labelQR.text = "发现人脸"
                
            }
        }
        //如果是条形码
        if let kkobject = metadataObjects.first as? AVMetadataMachineReadableCodeObject{
            let barcodeObject = videoPreviewLayout?.transformedMetadataObjectForMetadataObject(kkobject) as! AVMetadataMachineReadableCodeObject
            autolockView?.frame = barcodeObject.bounds
            switch kkobject.type {
            case AVMetadataObjectTypeQRCode:
                if let descodeStr = kkobject.stringValue {
                    stopScan()
                    labelQR.text = "二维码" + descodeStr
                    
                    launchAPP(descodeStr)
                    
                }
            case AVMetadataObjectTypeEAN13Code:
                if let descodeStr = kkobject.stringValue {
                    stopScan()
                    labelQR.text = "商品码、条形码" + descodeStr
                    showGodsName(descodeStr)
                }
            default:return
            }
        }
        
    }
    //打开一个Url对应的程序
    func launchAPP(descodeStr: String) {
        let alert = UIAlertController(title: "二维码", message: "将要打开\(descodeStr)", preferredStyle: UIAlertControllerStyle.ActionSheet)
        let okAction = UIAlertAction(title: "打开", style: UIAlertActionStyle.Destructive) { (_) -> Void in
            if let url = NSURL(string: descodeStr) {
                if UIApplication.sharedApplication().canOpenURL(url) {
                    UIApplication.sharedApplication().openURL(url)
                }
            }
        }
        alert.addAction(okAction)
        
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = labelQR.frame
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    //获取商品名
    func showGodsName(descodeStr: String) {
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        let baseURL = "http://api.juheapi.com/jhbar/bar?appkey=&pkg=&cityid=&barcode="
        
        let request = NSURLRequest(URL: NSURL(string: baseURL + descodeStr)!)
        
        let task = session.dataTaskWithRequest(request) { (data, _, error) -> Void in
            if error == nil {
                do {
                    if let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary {
                        print(json)
                        
                        if let sumary = json["result"]?["summary"] as? NSDictionary {
                            let name = sumary["name"] as? String
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.labelQR.text = self.labelQR.text! + "" + name!
                            })
                            
                            
                        }
                    }
                }
                catch {
                    print("不能转换")
                }
            }
        }
        task .resume()
    }

}




















