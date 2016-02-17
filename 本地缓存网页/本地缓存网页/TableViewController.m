//
//  TableViewController.m
//  本地缓存网页
//
//  Created by jojojiong on 16/1/8.
//  Copyright © 2016年 jojojiong. All rights reserved.
//

#import "TableViewController.h"
#import <Masonry.h>
#import "FMDB.h"
#import "Article.h"
#import "WebViewController.h"

#define ROOT_URL @"http://movie.ruiyuedigi.com" //http://121.40.95.177 http://movie.ruiyuedigi.com  http://moviewapp.dazui.com
#define ARTICEL_URL [NSString stringWithFormat:@"%@/article/detailv2?id=",ROOT_URL]

@interface TableViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>
@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) FMDatabase *db;

@end

@implementation TableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableview = ({
        UITableView *view = [UITableView new];
        [self.view addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        view.delegate = self;
        view.dataSource = self;
        view;
    });
    
    self.listArray = [[NSMutableArray alloc] init];
    
    // 1.获得数据库文件的路径
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filename = [doc stringByAppendingPathComponent:@"news.sqlite"];
    
    // 2.得到数据库
    FMDatabase *db = [FMDatabase databaseWithPath:filename];
    
    // 打开数据库
    [db open];
    
    // 1.执行查询语句
    FMResultSet *resultSet = [db executeQuery:@"SELECT * FROM downloadnews"];
    
    
    // 2.遍历结果
    while ([resultSet next])
    {
        int ID = [resultSet intForColumn:@"id"];
        NSString *idStr = [NSString stringWithFormat:@"%d",ID];
        NSString *titleStr = [resultSet stringForColumn:@"title"];
        NSString *summaryStr = [resultSet stringForColumn:@"summary"];
        
        Article *article = [[Article alloc] init];
        article.id = idStr;
        article.title = titleStr;
        article.summary = summaryStr;
        
        [self.listArray addObject:article];
    
    }
    
   
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableView) name:@"todayDataGet" object:nil];
}

- (void)updateTableView
{
    [self.tableview reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.listArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    Article *article = self.listArray[indexPath.row];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSArray *readNewsIdArray = [user objectForKey:@"readNewsId"];

    cell.textLabel.text = article.title;
    
    if ([readNewsIdArray containsObject:article.id]) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    cell.detailTextLabel.text = article.summary;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Article *article = self.listArray[indexPath.row];
    NSString *weburl = [ARTICEL_URL stringByAppendingString:article.id];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSMutableArray *readNewsIdArray = [NSMutableArray arrayWithArray:[user objectForKey:@"readNewsId"]];
    [readNewsIdArray addObject:article.id];
    [user setObject:readNewsIdArray forKey:@"readNewsId"];
    
    
    
    WebViewController *webviewController = [[WebViewController alloc] init];
    webviewController.articleId = article.id;
    webviewController.webUrl = weburl;
    NSLog(@"%@",weburl);
    [self.navigationController pushViewController:webviewController animated:YES];
}

@end
