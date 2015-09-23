//
//  FtpViewController.m
//  ftp
//
//  Created by St.Pons Mr.G on 15/9/22.
//  Copyright © 2015年 fish. All rights reserved.
//

#import "FtpViewController.h"

@interface FtpViewController ()<NSStreamDelegate>

@end

@implementation FtpViewController{
    NSMutableArray *_items;
    NSString *_host,*_user,*_pwd;
    NSOutputStream *_dirStream,*_uploadStream;
}

-(instancetype) initWithHost:(NSString *)host user:(NSString *)user pwd:(NSString *)pwd{
    if (self = [super init]) {
        _host = host;
        _user = user;
        _pwd = pwd;
        _items = [NSMutableArray array];
    }
    return self;
}

-(NSString *)_rootHost{
    NSString *url = @"";
    if (_user.length > 0) {
        url = [NSString stringWithFormat:@"ftp://%@:%@@%@",_user,_pwd,_host];
    }else{
        url = [NSString stringWithFormat:@"ftp://%@",_host];
    }
    return url;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *url = [self _rootHost];
        NSLog(@"%@",url);
        NSError *err;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url] options:NSDataReadingMappedAlways error:&err];
        NSAssert1(err == nil, @"ftp错误%@", err);
        NSLog(@"%d",data.length);
        CFDictionaryRef thisEntry = NULL;
        NSUInteger offset = 0;
        while (offset < data.length) {
            CFIndex bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *) data.bytes)[offset], (CFIndex) ([data length] - offset), &thisEntry);
            NSDictionary *dic = (__bridge NSDictionary *)thisEntry;
            NSLog(@"%d,文件信息有这些, 需要的自己去解析%@",(int)bytesConsumed,dic);
            offset += bytesConsumed;
            [_items addObject:dic[(__bridge NSString *)kCFFTPResourceName]];
        }
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
    UIButton *dirBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [dirBtn setTitle:@"文件夹" forState:UIControlStateNormal];
    self.navigationItem.titleView = dirBtn;
    dirBtn.backgroundColor = [UIColor blueColor];
    [dirBtn addTarget:self action:@selector(_dir) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *uploadBtn =[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 30)];
    [uploadBtn setTitle:@"上传" forState:UIControlStateNormal];
    uploadBtn.backgroundColor = [UIColor blueColor];
    [uploadBtn addTarget:self action:@selector(_upload) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:uploadBtn];
}

-(void)_upload{
    NSString *url = [NSString stringWithFormat:@"%@/pub/ddd.png",[self _rootHost]];
    NSLog(@"%@",url);
    CFWriteStreamRef streamRef = CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)[NSURL URLWithString:url]);
    _uploadStream = CFBridgingRelease(streamRef);
    NSParameterAssert(_uploadStream != nil);
    _uploadStream.delegate = self;
    [_uploadStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_uploadStream open];
}

-(void)_dir{
    NSString *url = [NSString stringWithFormat:@"%@/pub/%@/",[self _rootHost],[NSDate.date.description substringToIndex:4]];
    NSLog(@"%@",url);
    CFWriteStreamRef streamRef = CFWriteStreamCreateWithFTPURL(NULL, (__bridge CFURLRef)[NSURL URLWithString:url]);
    _dirStream = CFBridgingRelease(streamRef);
    NSParameterAssert(_dirStream != nil);
    _dirStream.delegate = self;
    [_dirStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_dirStream open];
}

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{
    NSLog(@"%d",eventCode);
    if (aStream == _dirStream) {
        if (eventCode == NSStreamEventErrorOccurred) {
            CFStreamError err = CFWriteStreamGetError((__bridge CFWriteStreamRef)(NSOutputStream *)aStream);
            //对着这里去看http://www.360doc.com/content/13/0108/11/8827884_258914553.shtml
            if (err.error == 550) {
                NSLog(@"创建文件夹失败, 请看权限和文件是否重复");
            }else{
                NSLog(@"err:%d",(int)err.error);
            }
        }else if (NSStreamEventOpenCompleted == eventCode){
            NSLog(@"流打开成功");
        }else if (eventCode == NSStreamEventHasSpaceAvailable){
            NSLog(@"NSStreamEventHasSpaceAvailable");
        }else if (eventCode == NSStreamEventEndEncountered){
            NSLog(@"NSStreamEventEndEncountered");
        }else{
            NSLog(@"未知");
        }
    }else{
        if (NSStreamEventOpenCompleted == eventCode){
            NSLog(@"流打开成功");
        }else if (eventCode == NSStreamEventHasSpaceAvailable){
            NSLog(@"NSStreamEventHasSpaceAvailable");
            NSString *path = [[NSBundle mainBundle] pathForResource:@"ddd" ofType:@"png"];
            NSData *data  =[NSData dataWithContentsOfFile:path];
            NSInteger len = [_uploadStream write:data.bytes maxLength:data.length];
            NSLog(@"已长度%d,总长度%d",len,data.length);
            [_uploadStream removeFromRunLoop:[NSRunLoop currentRunLoop]  forMode:NSDefaultRunLoopMode];
            [_uploadStream close];
            NSLog(@"已经上传成功");
        }else if (eventCode == NSStreamEventEndEncountered){
            NSLog(@"NSStreamEventEndEncountered");
        }else if (eventCode == NSStreamEventErrorOccurred){
            NSLog(@"报错了");
        }else{
            NSLog(@"未知");
        }
    }
}
#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _items.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = _items[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([_items[indexPath.row] hasSuffix:@"jpg"]) {
        NSString *url = [NSString stringWithFormat:@"%@/%@",[self _rootHost],_items[indexPath.row]];
        NSError *err;
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:url] options:NSDataReadingMappedAlways error:&err];
        NSAssert1(err == nil, @"ftp错误%@", err);//550大概是文件夹已经存在
        UIImageView *iView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
        iView.image = [UIImage imageWithData:data];
        tableView.tableHeaderView = iView;
    }
}
@end
