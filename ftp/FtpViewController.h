//
//  FtpViewController.h
//  ftp
//
//  Created by St.Pons Mr.G on 15/9/22.
//  Copyright © 2015年 fish. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FtpViewController : UITableViewController
-(instancetype) initWithHost:(NSString *)host user:(NSString *)user pwd:(NSString *)pwd;
@end
