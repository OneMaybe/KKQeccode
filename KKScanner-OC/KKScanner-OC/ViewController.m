//
//  ViewController.m
//  KKScanner-OC
//
//  Created by bcmac3 on 15/8/18.
//  Copyright (c) 2015年 KellenYang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate>
@property (weak, nonatomic) IBOutlet UIView *myView;
@property (weak, nonatomic) IBOutlet UILabel *labelQR;
@property (weak, nonatomic) IBOutlet UIButton *buttonReScan;
@property (strong, nonatomic) AVCaptureSession *session; //视频捕捉会话
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayout; //视频画面预览图
@property (strong, nonatomic) UIView *autolockView; //自动锁定小方框
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _buttonReScan.hidden = YES;
    
    
    //1. 初始化视频捕捉会话
    _session = [[AVCaptureSession alloc] init];
    //2. 指定设备是摄像头
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //3. 输入
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil]
    ;
    if (input) {
        [_session addInput:input];
    }else{
        NSLog(@"无法使用摄像头");
    }
    //4. 输出
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [_session addOutput:output];
    //5. 添加元数据对象输出代理
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //6. 输出类型
    output.metadataObjectTypes = @[AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeFace];
    //7. 视频预览层 与 视频捕捉会话关联
    _videoPreviewLayout = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    _videoPreviewLayout.videoGravity = AVLayerVideoGravityResizeAspectFill;
    NSLog(@"%@",NSStringFromCGRect(_myView.layer.bounds));
    _videoPreviewLayout.frame = _myView.layer.bounds;
    [_myView.layer addSublayer:_videoPreviewLayout];
    
    //8. 启动会话
    [_session startRunning];
    
    //自动锁定框初始化
    
    _autolockView = [UIView new];
    _autolockView.layer.borderColor = [UIColor redColor].CGColor;
    _autolockView.layer.borderWidth = 2;
    [_myView addSubview:_autolockView];
    [_myView bringSubviewToFront:_autolockView];
    
}

//一旦视频捕捉有输出
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects == nil || metadataObjects.count == 0) {
        _autolockView.frame = CGRectZero;
        _labelQR.text = @"正在扫描";
        return;
    }
    //人脸
    if ([metadataObjects.firstObject isKindOfClass:[AVMetadataFaceObject class]]) {
        AVMetadataFaceObject *obj = (AVMetadataFaceObject *)metadataObjects.firstObject;
        if (obj.type == AVMetadataObjectTypeFace) {
            AVMetadataFaceObject *faceObj = (AVMetadataFaceObject *)[_videoPreviewLayout transformedMetadataObjectForMetadataObject:obj];
            _autolockView.frame = faceObj.bounds;
            _labelQR.text = @"发现人脸";
        }
    }
    //条形码
    if ([metadataObjects.firstObject isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
        AVMetadataMachineReadableCodeObject *obj = (AVMetadataMachineReadableCodeObject *)metadataObjects.firstObject;
        
        AVMetadataMachineReadableCodeObject *faceObj = (AVMetadataMachineReadableCodeObject *)[_videoPreviewLayout transformedMetadataObjectForMetadataObject:obj];
        _autolockView.frame = faceObj.bounds;
        
        if (obj.type == AVMetadataObjectTypeQRCode) {
            [self stopScan];
            NSString *descodeStr = obj.stringValue;
            _labelQR.text = [NSString stringWithFormat:@"二维码：%@",descodeStr];
            [self launchAPP:descodeStr];
        }else if(obj.type == AVMetadataObjectTypeEAN13Code) {
            [self stopScan];
            NSString *descodeStr = obj.stringValue;
            _labelQR.text = [NSString stringWithFormat:@"商品码/条形码：%@",descodeStr];
            [self showGodsName:descodeStr];
        }
    }

}

- (IBAction)reScan:(id)sender {
    [_session startRunning];
    _buttonReScan.hidden = YES;
}

- (void)stopScan {
    [_session stopRunning];
    _buttonReScan.hidden = NO;
    [_myView bringSubviewToFront:_buttonReScan];
    
}

- (void)launchAPP:(NSString *)descode {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"二维码" message:descode preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:descode];
        if ([[UIApplication sharedApplication] canOpenURL:url]) {
            [[UIApplication sharedApplication] openURL:url];
        }
    }];
    [alert addAction:okAction];
    //Ipad
    alert.popoverPresentationController.sourceView = self.view;
    alert.popoverPresentationController.sourceRect = _labelQR.frame;
    
    [self presentViewController:alert animated:YES completion:nil];
    
}
/*
 http://api.juheapi.com/jhbar/bar?appkey=key&pkg=com.thinkland.test&barcode=6923450605332&cityid=1
 94076851270e5a349af35e2141e7ea7b
 com.kkqcode
 */


- (void)showGodsName:(NSString *)descode {
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSString *baseUrl = @"http://api.juheapi.com/jhbar/bar?appkey=94076851270e5a349af35e2141e7ea7b&pkg=com.kkqcode&cityid=1&barcode=";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",baseUrl,descode]]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        if (json) {
            NSLog(@"json = %@",json);
            NSDictionary *summary = json[@"result"][@"summary"];
            NSString *name = summary[@"name"];
            dispatch_async(dispatch_get_main_queue(), ^{
                _labelQR.text = name;
            });
        }else{
            NSLog(@"不能转换");
        }
    }];
    [task resume];
}

@end


















































