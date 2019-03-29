//
//  ViewController.m
//  CrashTest
//
//  Created by niujf on 2019/3/28.
//  Copyright © 2019年 niujf. All rights reserved.
//

#import "ViewController.h"
#import "SVProgressHUD.h"

@interface ViewController ()

@property (nonatomic,assign) UIButton *btn;
@property (nonatomic,assign) UIButton *testBtn;

@end

typedef struct Test{
    int a;
    int b;
}Test;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.btn = ({
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:@"崩溃调试" forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor redColor];
        btn.frame = CGRectMake(100, 100, 100, 100);
        [btn addTarget:self action:@selector(btnClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
        btn;
    });
}

- (void)btnClicked{
//    NSMutableArray *arr = @[].mutableCopy;
//    [arr removeObjectAtIndex:2];
    
//    [self performSelectorOnMainThread:@selector(handleException:) withObject:@"" waitUntilDone:YES];
    
    //导致SIGSEGV的错误，一般会导致进程流产
//    UIView *view = [[UIView alloc] init];
//    [view release];
//    [self.view addSubview:view];
    
    //导致SIGABRT的错误，因为内存中根本就没有这个空间，哪来的free，就在栈中的对象而已
//    Test *pTest = {1,2};
//    free(pTest);
//    pTest->a = 5;
    
    //SIGBUS，内存地址未对齐
//    char *s = "hello world";
//    *s = 'H';
}

@end
