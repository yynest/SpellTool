//
//  ViewController.m
//  SpellTool
//
//  Created by Fedora on 2018/11/6.
//  Copyright © 2018 Fedora. All rights reserved.
//

#import "ViewController.h"
#import <AipOcrSdk/AipOcrSdk.h>
#import "ComDefined.h"
#import "NSString+YYTransformPinyin.h"


@interface ViewController () <UIAlertViewDelegate> {
    UITextView *textView;
}

@end

@implementation ViewController {
    // 默认的识别成功的回调
    void (^_successHandler)(id);
    // 默认的识别失败的回调
    void (^_failHandler)(NSError *);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //     授权方法1：在此处填写App的Api Key/Secret Key
//    [[AipOcrService shardService] authWithAK:@"hYvAmT5b522dBtjQmpjs5k6H" andSK:@"Bc253oivGqm6kPZNZ776xrXzRww0Gf5N"];
    
    
    // 授权方法2（更安全）： 下载授权文件，添加至资源
        NSString *licenseFile = [[NSBundle mainBundle] pathForResource:@"aip" ofType:@"license"];
        NSData *licenseFileData = [NSData dataWithContentsOfFile:licenseFile];
        if(!licenseFileData) {
            [[[UIAlertView alloc] initWithTitle:@"授权失败" message:@"授权文件不存在" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        }
        [[AipOcrService shardService] authWithLicenseFileData:licenseFileData];
    
    [self configCallback];
    
    CGFloat width = MAIN_SCREEN_WIDTH;
    CGFloat height = MAIN_SCREEN_HEIGHT;
    CGFloat widthButton = 100;
    CGFloat edge = 20;
    //文本
    textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 20, width, height - widthButton - edge)];
    textView.backgroundColor = [UIColor lightGrayColor];
    textView.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:textView];
    
    //按钮
    UIButton *bt_scan = [[UIButton alloc] initWithFrame:CGRectMake((width - widthButton)/2, height -  widthButton, widthButton, widthButton)];
    [bt_scan setBackgroundColor:[UIColor greenColor]];
    [bt_scan setTitle:@"拍照" forState:UIControlStateNormal];
    [bt_scan setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [bt_scan addTarget:self action:@selector(generalOCR) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:bt_scan];
}

- (void)configCallback {
    __weak typeof(self) weakSelf = self;

    // 这是默认的识别成功的回调
    _successHandler = ^(id result){
        NSLog(@"%@", result);
        NSString *title = @"识别结果";
        NSMutableString *message = [NSMutableString string];

        if(result[@"words_result"]){
            if([result[@"words_result"] isKindOfClass:[NSDictionary class]]){
                [result[@"words_result"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    if([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:@"words"]){
                        [message appendFormat:@"%@: %@\n", key, obj[@"words"]];
                    }else{
                        [message appendFormat:@"%@: %@\n", key, obj];
                    }

                }];
            }else if([result[@"words_result"] isKindOfClass:[NSArray class]]){
                for(NSDictionary *obj in result[@"words_result"]){
                    if([obj isKindOfClass:[NSDictionary class]] && [obj objectForKey:@"words"]){
                        [message appendFormat:@"%@\n", obj[@"words"]];
                    }else{
                        [message appendFormat:@"%@\n", obj];
                    }

                }
            }

        }else{
            [message appendFormat:@"%@", result];
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:weakSelf cancelButtonTitle:@"确定" otherButtonTitles:nil];
//            [alertView show];
            NSString *pinyin = [message transformToPinyin];
            textView.text = [NSString stringWithFormat:@"%@\n%@",message,pinyin];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    };

    _failHandler = ^(NSError *error){
        NSLog(@"%@", error);
        NSString *msg = [NSString stringWithFormat:@"%li:%@", (long)[error code], [error localizedDescription]];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[[UIAlertView alloc] initWithTitle:@"识别失败" message:msg delegate:weakSelf cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        }];
    };
}

#pragma mark - Action
- (void)generalOCR{

    UIViewController * vc = [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
        // 在这个block里，image即为切好的图片，可自行选择如何处理
        NSDictionary *options = @{@"language_type": @"CHN_ENG", @"detect_direction": @"true"};
        [[AipOcrService shardService] detectTextFromImage:image
                                              withOptions:options
                                           successHandler:_successHandler
                                              failHandler:_failHandler];

    }];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)generalEnchancedOCR{

    UIViewController * vc = [AipGeneralVC ViewControllerWithHandler:^(UIImage *image) {
        NSDictionary *options = @{@"language_type": @"CHN_ENG", @"detect_direction": @"true"};
        [[AipOcrService shardService] detectTextEnhancedFromImage:image
                                                      withOptions:options
                                                   successHandler:_successHandler
                                                      failHandler:_failHandler];

    }];
    [self presentViewController:vc animated:YES completion:nil];
}


#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
