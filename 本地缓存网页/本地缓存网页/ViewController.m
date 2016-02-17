//
//  ViewController.m
//  本地缓存网页
//
//  Created by jojojiong on 16/1/4.
//  Copyright © 2016年 jojojiong. All rights reserved.
//

#import "ViewController.h"
#import <Masonry.h>
#import <AFNetworking/AFNetworking.h>
#import <MJExtension.h>
#import "Article.h"
#import "WebViewController.h"


#define ROOT_URL @"http://movie.ruiyuedigi.com" //http://121.40.95.177 http://movie.ruiyuedigi.com  http://moviewapp.dazui.com
#define LIST_URL [NSString stringWithFormat:@"%@/APIV2/article/getlist",ROOT_URL]
#define ARTICEL_URL [NSString stringWithFormat:@"%@/article/detailv2?id=",ROOT_URL]


@interface ViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>
@property (nonatomic, strong) UITableView *tableview;
@property (nonatomic, strong) NSArray *articleArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    
    
  
    
    NSURL *URL = [NSURL URLWithString:LIST_URL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    [manager GET:URL.absoluteString parameters:nil success:^(NSURLSessionTask *task, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
        self.articleArray = [Article mj_objectArrayWithKeyValuesArray:responseObject];
        [self.tableview reloadData];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
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

- (void)touched
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSLog(@"aaaa");
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.articleArray.count;
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
    
    Article *article = self.articleArray[indexPath.row];
    
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSArray *readNewsIdArray = [user objectForKey:@"readNewsId"];
    
    cell.textLabel.text = article.title;
    cell.detailTextLabel.text = article.summary;
    
    if ([readNewsIdArray containsObject:article.id]) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    } else {
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    
//    cell.imageView.image = [UIImage imageNamed:article.pic];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Article *article = self.articleArray[indexPath.row];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
