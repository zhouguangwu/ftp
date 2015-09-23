//
//  ViewController.m
//  ftp
//
//  Created by St.Pons Mr.G on 15/9/22.
//  Copyright © 2015年 fish. All rights reserved.
//

#import "ViewController.h"
#import "FtpViewController.h"
@interface ViewController (){
    
    IBOutlet UITextField *_passwordField;
    IBOutlet UITextField *_usernameField;
    IBOutlet UITextField *_hostField;
}

@end

@implementation ViewController{
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)_login:(id)sender {
    if (_hostField.text.length == 0) {
        NSLog(@"地址空");
        UIAlertController *c = [UIAlertController alertControllerWithTitle:@"地址空" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self dismissViewControllerAnimated:YES completion:^{}];
                                                              }];
        
        [c addAction:defaultAction];
        [self presentViewController:c animated:YES completion:^{}];
    }else{
        FtpViewController *c = [[FtpViewController alloc] initWithHost:_hostField.text user:_usernameField.text pwd:_passwordField.text];
        [self.navigationController pushViewController:c animated:YES];
    }
}


@end
