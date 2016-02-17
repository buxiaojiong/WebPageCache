//
//  FirstViewController.m
//  本地缓存网页
//
//  Created by jojojiong on 16/1/5.
//  Copyright © 2016年 jojojiong. All rights reserved.
//

#import "FirstViewController.h"
#import <Masonry.h>
#import "ViewController.h"
#import "FMDB.h"
#import "TableViewController.h"
#import <AFNetworking/AFNetworking.h>
#import <MJExtension.h>
#import "Article.h"
#import <SDWebImageManager.h>

#define ROOT_URL @"http://movie.ruiyuedigi.com" //http://121.40.95.177 http://movie.ruiyuedigi.com  http://moviewapp.dazui.com
#define LIST_URL [NSString stringWithFormat:@"%@/APIV2/article/getlist",ROOT_URL]
#define ARTICEL_URL [NSString stringWithFormat:@"%@/article/detailv2?id=",ROOT_URL]

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    CGSize size = CGSizeMake(150, 50);
    
    UIButton *v1 = ({
        UIButton *view = [UIButton new];
        [self.view addSubview:view];
        
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.center.equalTo(self.view).centerOffset(CGPointMake(0, -100));
        }];
        [view setTitle:@"缓存10条数据" forState:UIControlStateNormal];
        [view addTarget:self action:@selector(downloadDataFirst) forControlEvents:UIControlEventTouchUpInside];
        view.backgroundColor = [UIColor redColor];
        view;
    });
    
    UIButton *v2 = ({
        UIButton *view = [UIButton new];
        [self.view addSubview:view];
        
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.center.equalTo(self.view);
        
        }];
        [view setTitle:@"缓存点击过的cell" forState:UIControlStateNormal];
        [view addTarget:self action:@selector(downloadTouchedData) forControlEvents:UIControlEventTouchUpInside];
        view.backgroundColor = [UIColor redColor];
        view;
    });
    
    UIButton *v3 = ({
        UIButton *view = [UIButton new];
        [self.view addSubview:view];
        
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(size);
            make.center.equalTo(self.view).centerOffset(CGPointMake(0, 100));
            
        }];
        [view setTitle:@"清空所有缓存" forState:UIControlStateNormal];
        [view addTarget:self action:@selector(removeAllDownload) forControlEvents:UIControlEventTouchUpInside];
        view.backgroundColor = [UIColor redColor];
        view;
    });
}

- (void)downloadDataFirst
{
    NSURL *URL = [NSURL URLWithString:LIST_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];                                             
    
    [manager GET:URL.absoluteString parameters:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        NSArray *array = [Article mj_objectArrayWithKeyValuesArray:responseObject];
        
        // 1.获得数据库文件的路径
        NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *filename = [doc stringByAppendingPathComponent:@"news.sqlite"];
        
        // 2.得到数据库
        FMDatabase *db = [FMDatabase databaseWithPath:filename];
        
        // 打开数据库
        if ([db open]) {
            // 4.创表
            BOOL result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS downloadnews (id integer PRIMARY KEY , title text NOT NULL , summary text NOT NULL);"];
            BOOL result2 =  [db executeUpdate:@"CREATE TABLE IF NOT EXISTS news_1 (id integer PRIMARY KEY , htmlStr text NOT NULL);"];
            
            if (result && result2) {
                NSLog(@"成功创表");
            } else {
                NSLog(@"创表失败");
            }
        }
        
        BOOL results = false;
        
        for (Article *article in array) {
            results = [db executeUpdate:@"INSERT INTO downloadnews (id, title , summary) VALUES (?, ?, ?);", article.id ,article.title ,article.summary];
            
            NSString *weburl = [ARTICEL_URL stringByAppendingString:article.id];
            
            NSURL *URL = [NSURL URLWithString:weburl];
            
            NSData *htmlData = [[NSData alloc] initWithContentsOfURL:URL];
            
            NSString *htmlStrs = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
            
            NSLog(@"%@",htmlStrs);
            
            //将html代码保存到数据库
            
            [db executeUpdate:@"INSERT INTO news_1 (id, htmlStr) VALUES (?, ?);", article.id, htmlStrs];
        }
        
        NSString *resultStr;
        if (results)
        {
            resultStr = @"缓存成功";
        }
        else
        {
            resultStr = @"缓存失败";
        }
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"结果"
                                                                       message:resultStr
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                              
                                                                  TableViewController *tvc = [[TableViewController alloc] init];
                                                                  [self.navigationController pushViewController:tvc animated:YES];
                                                              }];
        
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        

        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)downloadTouchedData
{
    ViewController *vc = [[ViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)removeAllDownload
{
    // 1.获得数据库文件的路径
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filename = [doc stringByAppendingPathComponent:@"news.sqlite"];
    
    // 2.得到数据库
    FMDatabase *db = [FMDatabase databaseWithPath:filename];
    
    [db open];
    
    BOOL result = [db executeUpdate:@"drop table if exists news_1;"];
    BOOL result2 = [db executeUpdate:@"drop table if exists images;"];
    BOOL result3 = [db executeUpdate:@"drop table if exists downloadnews"];
    
    NSString *extension = @"png";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
  
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filenames;
    while ((filenames = [e nextObject]))
    {
        if ([[filenames pathExtension] isEqualToString:extension])
        {
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filenames] error:NULL];
        }
    }
    
    [[SDWebImageManager sharedManager].imageCache clearDisk];
    
    NSString *resultStr;
    if (result && result2 && result3)
    {
        resultStr = @"删除成功";
    }
    else
    {
        resultStr = @"删除失败";
    }
    
    [db close];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"结果"
                                                                   message:resultStr
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
