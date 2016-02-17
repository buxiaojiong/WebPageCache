//
//  Article.h
//  本地缓存网页
//
//  Created by jojojiong on 16/1/4.
//  Copyright © 2016年 jojojiong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Article : NSObject

@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *createtime;
@property (nonatomic, copy) NSString *location;
@property (nonatomic, copy) NSString *pic;
@property (nonatomic, copy) NSString *pics;
@property (nonatomic, assign) BOOL istopic;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSDictionary *subtype;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *commentcount;
@property (nonatomic, copy) NSString *sharecount;
@property (nonatomic, copy) NSString *prize;

//"id":41,
//"title":"新闻1",
//"summary":"简介",//在新片和审片栏目下,该值为英文电影名
//"createtime":"\/Date(1431588060000)\/",
//"location":"好莱坞",
//"pic":"/Images/201505/20150514151952849.png",
//"pics":"/images/12.jpg|/images/23.jpg" , // 内容图,可能不存在(null),如果存在多个,中间以字符'|'分割   since 2.8.11
//"istopic":false, // 是否为专题,当该值为true时说明该数据是一篇专题
//"type":1,//影片类型,对应为:1色情,2动作,3喜剧,4记录,5....
//"subtype":{"id":1,name:"瞬间"}
//"tag":"蜘蛛侠",//标签
//"category":1,//类型  1新闻,2审片,3新片4俱乐部,5专题文章,6图赏
//"commentcount":12,//评论数
//"sharecount":12,//分享数
//"prize":0 // 评分,在审片列表中该值有效

@end
