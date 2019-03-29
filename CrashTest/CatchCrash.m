//
//  UncaughtExceptionHandlerTool.m
//  CrashTest
//
//  Created by niujf on 2019/3/28.
//  Copyright © 2019年 niujf. All rights reserved.
//

#import "CatchCrash.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <UIKit/UIKit.h>
#import "SVProgressHUD.h"

// 沙盒的地址
NSString * applicationDocumentsDirectory() {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

static NSString * const kSignalExceptionName = @"kSignalExceptionName";
static NSString * const kSignalKey = @"kSignalKey";
static NSString * const kCaughtExceptionStackInfoKey = @"kCaughtExceptionStackInfoKey";


static NSUncaughtExceptionHandler *previousHandler;

@implementation CatchCrash

+ (void)defaultHandler {
    //保存handler
    previousHandler = NSGetUncaughtExceptionHandler();
    //1.捕获一些异常导致的崩溃
    NSSetUncaughtExceptionHandler(&UncaughtExceptionHandler);
    // 2.捕获非异常情况，通过signal传递出来的崩溃
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
}

+ (void)uploadCrash{
    // 发送崩溃日志
    NSString *dataPath = [applicationDocumentsDirectory() stringByAppendingPathComponent:@"Exception.txt"];
    NSData *data = [NSData dataWithContentsOfFile:dataPath];
    //转string
    NSString *crashStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (crashStr.length > 0) {
        [SVProgressHUD showInfoWithStatus:crashStr];
    }
    if (data != nil) {
            //上传服务器
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{//模拟上传成功之后,移除本地文件
            NSFileManager *fileManger = [NSFileManager defaultManager];
            [fileManger removeItemAtPath:dataPath error:nil];
        });
    }
}

// 崩溃时的回调函数
void UncaughtExceptionHandler(NSException * exception) {
    // 获取异常的堆栈信息
    NSArray *callStack = [exception callStackSymbols];
    //获取异常的名称
    NSString *exceptionName = [exception name];
    //获取异常的原因
    NSString *excepReason = [exception reason];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:callStack forKey:kCaughtExceptionStackInfoKey];
    NSException *customException = [NSException exceptionWithName:exceptionName reason:excepReason userInfo:userInfo];
    [CatchCrash performSelectorOnMainThread:@selector(handleException:) withObject:customException waitUntilDone:YES];
    //将异常塞给之前的第三方
    if (previousHandler) {
         previousHandler(exception);
    }
}

void SignalHandler(int signal)
{
    // 这种情况的崩溃信息，就另某他法来捕获吧
    NSArray *callStack = [CatchCrash backtrace];
    NSException *customException = [NSException exceptionWithName:kSignalExceptionName
                                                           reason:[NSString stringWithFormat:NSLocalizedString(@"Signal %d was raised.", nil),signal]
                                                         userInfo:@{kSignalKey:[NSNumber numberWithInt:signal]}];
    [CatchCrash performSelectorOnMainThread:@selector(handleException:) withObject:customException waitUntilDone:YES];
}

+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (int i = 0; i < frames; i++) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}

+ (void)handleException:(NSException *)exception
{
    NSString *exceptionInfo = [NSString stringWithFormat:@"========异常错误报告========:\n%@\n%@\n%@",[exception name],[exception reason],[[exception userInfo] objectForKey:kCaughtExceptionStackInfoKey]];
    NSString * path = [applicationDocumentsDirectory() stringByAppendingPathComponent:@"Exception.txt"];
    // 将一个txt文件写入沙盒
    [exceptionInfo writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
