//
//  CardScannerController.m
//  KKScanner-OC
//
//  Created by bcmac3 on 15/8/18.
//  Copyright (c) 2015年 KellenYang. All rights reserved.
//

#import "CardScannerController.h"
#import "CardIO.h"

@interface CardScannerController ()<CardIOPaymentViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@end

@implementation CardScannerController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [CardIOUtilities preload];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)startScanner:(id)sender {
    CardIOPaymentViewController *cardVC = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
    cardVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:cardVC animated:YES completion:nil];
}


- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)paymentViewController {
    _resultLabel.text = @"您取消了扫描";
    [paymentViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)cardInfo inPaymentViewController:(CardIOPaymentViewController *)paymentViewController {
    if (cardInfo) {
        _resultLabel.text = [NSString stringWithFormat:@"卡号：%@\n过期年月：%ld-%ld\nCVV：%@",cardInfo.cardNumber,cardInfo.expiryYear,cardInfo.expiryMonth,cardInfo.cvv];
    }
    [paymentViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
