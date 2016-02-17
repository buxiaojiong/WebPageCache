//
//  WebViewController.m
//  本地缓存网页
//
//  Created by jojojiong on 16/1/4.
//  Copyright © 2016年 jojojiong. All rights reserved.
//

#import "WebViewController.h"
#import <Masonry.h>
#import "FMDB.h"
#import "TFHpple.h"
#import "NSString+MD5hash.h"
#import <SDWebImageManager.h>
#import "WebViewJavascriptBridge.h"
#import <AFNetworking/AFNetworking.h>

#define ROOT_URL @"http://movie.ruiyuedigi.com"

#define KSIMGURL @"imgURL"
#define KSHEADURL @"headURL"
#define KSScreenWidth [UIScreen mainScreen].bounds.size.width
#define KSScreenHeight [UIScreen mainScreen].bounds.size.height

@interface WebViewController ()<UIWebViewDelegate>
{
    CGRect defaultRect;
    UIView *goBackgroundView;
}

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) FMDatabase *db;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableArray *listImage;
@property (nonatomic, strong) NSMutableArray *listRepalceImage;
@property (nonatomic, strong)WebViewJavascriptBridge *bridge;
@property (nonatomic, copy) NSString *htmlStr;
@property (nonatomic, strong) NSMutableArray *headImage;
@property (nonatomic, strong) NSMutableArray *headReplaceImage;

@end

@implementation WebViewController

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];

    self.webview = ({
        UIWebView *view = [UIWebView new];
        [self.view addSubview:view];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
        view.delegate = self;
        view;
    });
    
    NSURL *URL = [NSURL URLWithString:self.webUrl];
    
//    [self initJSbirdge];
    [self initDataBase];

    /*查询表中是否有网页ID相同的元素 有就加载本地缓存 没有就请求网络加载*/
    
    NSString *htmlStrs;
    if ([self checkTheWebIsLoaded])// 已经缓存过了的网页
    {
//        NSLog(@"从数据库中取出的self.htmlStr%@",self.htmlStr);
        
        NSData *htmlData = [self.htmlStr dataUsingEncoding:NSUTF8StringEncoding];
        
        [self getResourceListFromHtmlData:htmlData];
        
        htmlStrs = self.htmlStr;
    }
    else //没有缓存过的网页
    {
        //  获取html的nsdata数据
        NSData *htmlData = [[NSData alloc] initWithContentsOfURL:URL];
        
        if (!htmlData)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误"
                                                                           message:@"网络连接错误 请稍后再试"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            [self getResourceListFromHtmlData:htmlData];
            
            htmlStrs = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
            //将html代码保存到本地 路径保存到数据库
//            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//            NSString * filepaht=paths[0];
//            NSFileManager *fileManager = [NSFileManager defaultManager];
//            NSString *imageDir = [NSString stringWithFormat:@"%@/html",filepaht];
//            [fileManager createDirectoryAtPath:imageDir withIntermediateDirectories:YES attributes:nil error:nil];
//            NSString *name = [NSString md5Hash:self.webUrl];
//            NSString *htmlPaths = [NSString stringWithFormat:@"%@/%@.html",imageDir,name];
//            [htmlData writeToFile:htmlPaths atomically:YES];
            
            [self.db executeUpdate:@"INSERT INTO news_1 (id, htmlStr) VALUES (?, ?);", self.articleId, htmlStrs];
        }
    }
    
    for (NSString *headSrc in self.headReplaceImage)
    {
        htmlStrs = [htmlStrs stringByReplacingOccurrencesOfString:headSrc withString:KSHEADURL];
    }
    
    for (NSString *imaSrc in self.listRepalceImage)
    {
        htmlStrs = [htmlStrs stringByReplacingOccurrencesOfString:imaSrc withString:KSIMGURL];
    }
    
    NSLog(@"处理后的%@",htmlStrs);
    
    NSString *path = [[NSBundle mainBundle] resourcePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    [self.webview loadHTMLString:htmlStrs baseURL:baseURL];
    
    [self settheJscript];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.db closeOpenResultSets];
    [self.db close];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"todayDataGet" object:nil];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    
    NSString *urlStr = request.URL.absoluteString;
    
    if ([urlStr hasPrefix:@"openimg://"])
    {
        NSString *currentUrlstr = [urlStr stringByRemovingPercentEncoding];
        NSLog(@"%@",currentUrlstr);
        
        currentUrlstr = [currentUrlstr substringFromIndex:10];
        NSData *data = [currentUrlstr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        
        NSArray *imagePathArray = [dic objectForKey:@"images"];
        NSInteger index = [[NSString stringWithFormat:@"%@", dic[@"index"]] integerValue];
        NSString *imagePath = [imagePathArray objectAtIndex:index];
        
        imagePath = [imagePath substringFromIndex:7];
        [self showBigImage:imagePath];
        return NO;
    }
    
    return YES;
}
- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    [self performSelectorOnMainThread:@selector(getImageFromDownloaderOrDiskByImageUrlArray:ReplaceStr:) withObject:[NSNumber numberWithInt:1] waitUntilDone:0.1]; 
//    [self getImageFromDownloaderOrDiskByImageUrlArray:self.headImage ReplaceStr:KSHEADURL];
    [self getImageFromDownloaderOrDiskByImageUrlArray:self.listImage ReplaceStr:KSIMGURL];
    
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Picture" ofType:@"js"];
//    NSString *jsString = [[NSString alloc]initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
//    [self.webview stringByEvaluatingJavaScriptFromString:jsString];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(nullable NSError *)error
{
    
}

#pragma mark - 点击图片放大
-(void)showBigImage:(NSString *)imageName{
    UIImage *image = [UIImage imageWithContentsOfFile:imageName];
    UIImageView *defaultImageView = [[UIImageView alloc] initWithImage:image];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    goBackgroundView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, KSScreenWidth, KSScreenHeight)];
//    defaultRect = [defaultImageView convertRect:defaultImageView.bounds toView:window];//关键代码，坐标系转换
    defaultRect = CGRectMake(0, 100, KSScreenWidth, KSScreenHeight);
    
    goBackgroundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    
//    UIImageView *imageView = [[UIImageView alloc]initWithFrame:defaultRect];
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:defaultRect];
    
    imageView.image = image;
    imageView.tag = 1;
    
    NSLog(@"%@",NSStringFromCGRect(defaultRect));
    
    [goBackgroundView addSubview:imageView];
    [window addSubview:goBackgroundView];
   
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideImage:)];
    [goBackgroundView addGestureRecognizer:tap];

    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame = CGRectMake(0,(KSScreenHeight-image.size.height*KSScreenWidth/image.size.width)/2, KSScreenWidth, image.size.height*KSScreenWidth/image.size.width);
        NSLog(@"%@",NSStringFromCGRect(imageView.frame));
        
        goBackgroundView.backgroundColor=[UIColor blackColor];
        
    } completion:^(BOOL finished) {
    }];
}

- (void)hideImage:(UITapGestureRecognizer*)tap{
    UIImageView *imageView = (UIImageView*)[tap.view viewWithTag:1];
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame = defaultRect;
        goBackgroundView.backgroundColor=[UIColor colorWithRed:0 green:0 blue:0 alpha:0];
    } completion:^(BOOL finished) {
        [goBackgroundView removeFromSuperview];
    }];
}

#pragma mark -  查询网页是否被加载过
- (BOOL)checkTheWebIsLoaded
{
    BOOL isExist = NO;
    // 1.执行查询语句
    FMResultSet *resultSet = [self.db executeQuery:@"SELECT * FROM news_1"];
    
    NSString *strHtml;
    
    // 2.遍历结果
    while ([resultSet next])
    {
        int ID = [resultSet intForColumn:@"id"];
        strHtml = [resultSet stringForColumn:@"htmlStr"];
        NSLog(@"缓存的 %d  ", ID);
        
        NSString *arID = [NSString stringWithFormat:@"%d",ID];
        
        if ([arID isEqualToString:self.articleId] && ![strHtml  isEqual: @""])
        {
            isExist = YES;
            self.htmlStr = strHtml;
            break;
        }
        else
        {
            isExist = NO;
        }
    }
    return isExist;
}

#pragma mark - 初始化数据库
- (void)initDataBase
{
    // 获得数据库文件的路径
    NSString *doc = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *filename = [doc stringByAppendingPathComponent:@"news.sqlite"];
    
    // 得到数据库
    FMDatabase *db = [FMDatabase databaseWithPath:filename];
    
    // 打开数据库
    if ([db open]) {
        // 4.创表
        BOOL result = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS news_1 (id integer PRIMARY KEY , htmlStr text NOT NULL);"];
//        BOOL result2 = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS images (id integer PRIMARY KEY AUTOINCREMENT,imagekey text NOT NULL, imageUrl text);"];
        if (result) {
            NSLog(@"成功创表");
        } else {
            NSLog(@"创表失败");
        }
    }
    
    self.db = db;
}



#pragma mark - 解析HTML资源
- (void)getResourceListFromHtmlData:(NSData *)htmlData
{
    // 解析图片地址 用sdwebimage下载 然后吧路径存入数据库
    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:htmlData];
    
    NSArray *headArray = [xpathParser searchWithXPathQuery:@"//img"];
    for (TFHppleElement *hppleElement in headArray)
    {
        if ([[hppleElement objectForKey:@"id"] isEqualToString:@"galleryPlaceholder"])
        {
            NSString *scrImage = [hppleElement.attributes objectForKey:@"src"];
            
            NSString *string = [NSString stringWithFormat:@"%@%@", ROOT_URL,scrImage];
            [self.headImage addObject:string];
            
            NSString *replaceString = [NSString stringWithFormat:@"%@",scrImage];
            [self.headReplaceImage addObject:replaceString];
        }
    }
    
    NSArray *imageArray = [xpathParser searchWithXPathQuery:@"//div"];
    for (TFHppleElement *hppleElement in imageArray)
    {
        if ([[hppleElement objectForKey:@"class"] isEqualToString:@"galleryImage"])
        {
            NSString *bgurl = [hppleElement.attributes objectForKey:@"style"];
            NSRange range = NSMakeRange(22, 36);
            bgurl = [bgurl substringWithRange:range];
            
            NSString *string = [NSString stringWithFormat:@"%@%@", ROOT_URL,bgurl];
            [self.headImage addObject:string];
            
            NSString *replaceString = [NSString stringWithFormat:@"%@",bgurl];
            [self.headReplaceImage addObject:replaceString];
        }
    }
    
    NSArray *dataArray = [xpathParser searchWithXPathQuery:@"//img"];
    for (TFHppleElement *hppleElement in dataArray)
    {
        if ([[hppleElement objectForKey:@"alt"] isEqualToString:@""]) {
            NSString *scrImage = [hppleElement.attributes objectForKey:@"src"];
            
            NSString *string = [NSString stringWithFormat:@"%@%@", ROOT_URL, scrImage];
            [self.listImage addObject:string];
            
            [self.listRepalceImage addObject:scrImage];
        }
        

    }
    
    NSLog(@"headImage-------%@",self.headImage);
    NSLog(@"headReplaceImage--------%@",self.headReplaceImage);
    NSLog(@"listImage-------%@",self.listImage);
    NSLog(@"listRepalceImage--------%@",self.listRepalceImage);

    // 解析视屏地址
    NSArray *videoDataArray = [xpathParser searchWithXPathQuery:@"//source"];

    for (TFHppleElement *hppleElement in videoDataArray)
    {
        NSLog(@"%@",hppleElement.raw);
        NSLog(@"%@",hppleElement.text);
        
        NSString *string = [NSString stringWithFormat:@"%@%@", ROOT_URL, [hppleElement.attributes objectForKey:@"src"]];
        NSLog(@"video-----------------%@",string);
    }

}


#pragma mark - 注入JS
-(void)settheJscript
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"js"];
    NSString *jsString = [[NSString alloc]initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [self.webview stringByEvaluatingJavaScriptFromString:jsString];
    
//    [self performSelectorOnMainThread:@selector(setwebfinishFrame:) withObject:[NSNumber numberWithInt:1] waitUntilDone:0.1];
//    [webcontent stringByEvaluatingJavaScriptFromString:@"setImageClickFunction()"];
    
}

#pragma mark - 下载图片
- (void)getImageFromDownloaderOrDiskByImageUrlArray:(NSArray *)imageArray ReplaceStr:(NSString *)ReplaceStr
{
    SDWebImageManager *imageManager = [SDWebImageManager sharedManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * filepaht=paths[0];
    
//    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSString *imageDir = [NSString stringWithFormat:@"%@/Images",filepaht];
//    [fileManager createDirectoryAtPath:imageDir withIntermediateDirectories:YES attributes:nil error:nil];
 
    for (NSString *imgUrl in imageArray)
    {
        NSURL *imageUrl = [NSURL URLWithString:imgUrl];
        if ([imageManager diskImageExistsForURL:imageUrl])//已经缓存过了的图片 从本地取出 在通过传到网页上
        {
            
            NSString *name = [NSString md5Hash:imgUrl];
            NSString *imagePaths = [NSString stringWithFormat:@"%@/%@.png",filepaht,name];
            NSLog(@"取出的图片地址imagePaths === %@\n",imagePaths);
 
//            [_bridge send:[NSString stringWithFormat:@"replaceimage%@,%@",replaceImg,imagePaths]];
//            [self settheJscript];
            
            if ([ReplaceStr isEqualToString:KSIMGURL])
            {
                 [self SetContentJsWithOldUrl:ReplaceStr NewUrl:imagePaths];
            }
            else if ([ReplaceStr isEqualToString:KSHEADURL])
            {
                NSString *sss = [NSString stringWithFormat:@"document.querySelector(\".galleryImage\").style.backgroundImage=\"url(\"+%@+\")\";",imagePaths];
                
                [self.webview stringByEvaluatingJavaScriptFromString:sss];
            }
           
        }
        else
        {
            [imageManager downloadImageWithURL:imageUrl options:SDWebImageRetryFailed progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                
                if (image && finished)//如果下载成功
                {
                    NSData * dataimage=UIImagePNGRepresentation(image);
                    NSString *name = [NSString md5Hash:imgUrl];
                    NSString *imagePaths = [NSString stringWithFormat:@"%@/%@.png",filepaht,name];
                    [dataimage writeToFile:imagePaths atomically:NO];
                    
                    NSLog(@"存入的图片地址imagePaths === %@",imagePaths);

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
//                        [_bridge send:[NSString stringWithFormat:@"replaceimage%@,%@",replaceImg,imagePaths]];
//                        [self settheJscript];
                        
                        if ([ReplaceStr isEqualToString:KSIMGURL])
                        {
                            [self SetContentJsWithOldUrl:ReplaceStr NewUrl:imagePaths];
                        }
                        else if ([ReplaceStr isEqualToString:KSHEADURL])
                        {
                            NSString *sss = [NSString stringWithFormat:@"document.querySelector(\".galleryImage\").style.backgroundImage=\"url(\"+%@+\")\";",imagePaths];
                            
                            [self.webview stringByEvaluatingJavaScriptFromString:sss];
                        }
                    });
                    
                }
                else
                {
                    
                }
                
            }];
            
        }
        
    }
}

- (void)SetContentJsWithOldUrl:(NSString *)OldUrl NewUrl:(NSString *)NewUrl
{
    NSString *sss = [NSString stringWithFormat:@"setImgUrl(\"%@\",\"%@\")",OldUrl,NewUrl];
    
    [self.webview stringByEvaluatingJavaScriptFromString:sss];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Picture" ofType:@"js"];
    NSString *jsString = [[NSString alloc]initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [self.webview stringByEvaluatingJavaScriptFromString:jsString];
}

#pragma mark - get方法
- (NSMutableArray *)listImage
{
    if (!_listImage) {
        _listImage = [[NSMutableArray alloc] init];
    }
    return _listImage;
}

- (NSMutableArray *)listRepalceImage
{
    if (!_listRepalceImage) {
        _listRepalceImage = [[NSMutableArray alloc] init];
    }
    return _listRepalceImage;
}

- (NSMutableArray *)headImage
{
    if (!_headImage) {
        _headImage = [[NSMutableArray alloc] init];
    }
    return _headImage;
}

- (NSMutableArray *)headReplaceImage
{
    if (!_headReplaceImage) {
        _headReplaceImage = [[NSMutableArray alloc] init];
    }
    return _headReplaceImage;
}

#pragma mark - 其他暂时不用的方法
- (void)downLoadImageFromURL:(NSArray* )imageUrlArray
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_group_t group = dispatch_group_create();
    
    for (int i = 0; i < imageUrlArray.count; i++)
    {
        NSString *imageUrl = [imageUrlArray objectAtIndex:i];
        NSString *key = [NSString md5Hash:imageUrl];
        
//        NSData *data = [FTWCache objectForKey:key];
        
        FMResultSet *resultSet = [self.db executeQuery:@"SELECT * FROM images"];
        // 2.遍历结果
        NSData *data;
        while ([resultSet next])
        {
            NSString *keyStr = [resultSet stringForColumn:@"imagekey"];
            NSData *datag = [resultSet dataForColumn:@"imageUrl"];
            
            if ([keyStr isEqualToString:key] )
            {
                data = datag;
                break;
            }
        }
        
        
        NSURL *imageURL = [NSURL URLWithString:imageUrl];
        NSString *index = [NSString stringWithFormat:@"%d", i];
        
        if (data)
        {
            [self.webview stringByEvaluatingJavaScriptFromString:[self createSetImageUrlJavaScript:index
                                                                                            imgUrl:key]];
        }
        else
        {
            dispatch_group_async(group, queue, ^{
                
                NSData *data = [NSData dataWithContentsOfURL:imageURL];
                if (data != nil)
                {
                    
//                    [FTWCache setObject:data forKey:key];
                    [self.db executeUpdate:@"INSERT INTO images (imagekey, imageData) VALUES (?, ?);", key, data];
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        
                        [self.webview stringByEvaluatingJavaScriptFromString:[self createSetImageUrlJavaScript:index
                                                                                                          imgUrl:key]];
                    });
                }
            });
            
        }
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        //这里是所有图片下载完成后执行的操作。
        
        
    });
//    dispatch_release(group);
}

//- (NSString *)replaceUrlSpecialString:(NSString *)string {
//
//    return [string stringByReplacingOccurrencesOfString:@"/"withString:@"_"];
//}

//设置下载完成的图片到web img
- (NSString *)createSetImageUrlJavaScript:(NSString *) index imgUrl:(NSString *) url
{
//    NSData *imageData = [FTWCache objectForKey:url];
    
    FMResultSet *resultSet = [self.db executeQuery:@"SELECT * FROM images"];
    // 2.遍历结果
    NSData *imageData;
    while ([resultSet next])
    {
        NSString *keyStr = [resultSet stringForColumn:@"imagekey"];
        NSData *datag = [resultSet dataForColumn:@"imageUrl"];
        
        if ([keyStr isEqualToString:url] )
        {
            imageData = datag;
            break;
        }
    }
    
    UIImage  *image = [UIImage imageWithData:imageData];
//    UIImageView *imv = [[UIImageView alloc] initWithImage:image];
//    imv.frame = CGRectMake(50, 100*[index intValue]+80, 320, 200);
//    [self.webview addSubview:imv];
//    int imageWidth = 300;
//    int imageHeight = image.size.height*300.0f/image.size.width;
    
    int imageWidth = [UIScreen mainScreen].bounds.size.width;
    int imageHeight = image.size.height*imageWidth/image.size.width;
    
    NSString *js = [NSString stringWithFormat:@"var imgArray = document.getElementsByTagName('img'); imgArray[%@].src=\"%@\"; imgArray[%@].width=\"%d\";imgArray[%@].height=\"%d\";" , index, url, index,imageWidth,index,imageHeight];

    return js;
}

#pragma mark - 初始化js与oc连接
- (void)initJSbirdge {
    
    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webview webViewDelegate:self handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"ObjC received message from JS: %@", data);
        responseCallback(@"Response for message from ObjC");
    }];
    
    [_bridge registerHandler:@"testObjcCallback" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"testObjcCallback called: %@", data);
        responseCallback(@"Response from testObjcCallback");
    }];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
