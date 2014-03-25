//
//  TableViewViewController.m
//  TestRAC
//
//  Created by AngerDragon on 14-2-28.
//  Copyright (c) 2014年 AngerDragon. All rights reserved.
//

#import "TableViewViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

//下面的两张图用在修改密码时，是否符合要求
#define  Wrong        [UIImage imageNamed:@"checkbox"]
#define  Right        [UIImage imageNamed:@"checkSelected"]


@interface TableViewViewController ()

@property(nonatomic,retain)UITextField *textFieldOne;

@property(nonatomic,retain)UITextField *textFieldTwo;

//创建2个输入框的信号源
@property(nonatomic,strong)RACSignal *textFieldOneSignal;
@property(nonatomic,strong)RACSignal *textFieldTwoSignal;

//创建一个合并的信号源
@property(nonatomic,strong)RACSignal *bothTwoTextFieldSignal;


@end

@implementation TableViewViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (indexPath.row == 0) {
            self.textFieldOne = [self creatTextFieldWithView:cell.contentView WithPlaceHolderStr:@"请输入:我爱刘力"];
            UIImageView * imageView = [self creatImageViewWithView:self.textFieldOne];
            self.textFieldOne.leftView = imageView;
            //信号创建
            self.textFieldOneSignal = [self.textFieldOne.rac_textSignal map:^id(NSString * value) {
                //返回下面这两个判断的值
                return @((value.length>=1)&&([value isEqualToString:@"我爱刘力"]));
            }];
            //map是改变自己的需求
            RAC(imageView,image) = [self.textFieldOneSignal map:^id(NSNumber * value) {
                if (value.boolValue) {
                    return Right;
                }
                return Wrong;
            }];
        }
        
        if (indexPath.row == 1) {
            
            self.textFieldTwo = [self creatTextFieldWithView:cell.contentView WithPlaceHolderStr:@"不能和上一个一样，但最后两字必须含“刘力”"];
            UIImageView * imageView = [self creatImageViewWithView:self.textFieldTwo];
            self.textFieldTwo.leftView = imageView;
            
            //将输入框2的enable属性和输入框1的信号源进行等价
            RAC(self.textFieldTwo,enabled) = self.textFieldOneSignal;
            [self.textFieldOneSignal subscribeNext:^(NSNumber *x) {
                if (![x boolValue]) {
                    self.textFieldTwo.enabled = NO;
                    self.textFieldTwo.placeholder = @"第一个不对，就没办法在我这输入，哈哈";
                }else
                {
                    self.textFieldTwo.enabled = YES;
                    self.textFieldTwo.placeholder = @"不能和上一个一样，但最后两字必须含“刘力”";
                }
            }];
            
            //信号创建
            self.textFieldTwoSignal = [self.textFieldTwo.rac_textSignal map:^id(NSString * value) {
                //返回下面这两个判断的值
                return @((value.length>=1)&&([value hasSuffix:@"刘力"])&&(![value isEqualToString:@"我爱刘力"]));
            }];
            //map是改变自己的需求
            RAC(imageView,image) = [self.textFieldTwoSignal map:^id(NSNumber * value) {
                if (value.boolValue) {
                    return Right;
                }
                return Wrong;
            }];
        }
    }
    
    if (indexPath.row == 2) {
        
        //在这个地方去指定合并信号源，因为前两个信号源已经生成
        self.bothTwoTextFieldSignal = [RACSignal combineLatest:@[self.textFieldOneSignal,self.textFieldTwoSignal] reduce:^(NSNumber*textFieldOne,NSNumber*textFieldTwo){

            //2个合并成一个，如果2个都符合条件，合并信号源也输出YES，否则NO
            return @(textFieldOne.boolValue&&textFieldTwo.boolValue);
        }];


        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        button.frame = cell.contentView.bounds;
        [cell.contentView addSubview:button];

        //将按钮的是否可点击与2个输入框是否符合条件进行绑定
        RAC(button,enabled)=self.bothTwoTextFieldSignal;
        //条件的扩展，改变颜色
        [self.bothTwoTextFieldSignal subscribeNext:^(NSNumber *x) {
            if (x.boolValue) {
                [button setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
                [button setTitle:@"恭喜你，你可以点我" forState:UIControlStateNormal];

            }else
            {
                [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
                [button setTitle:@"哎，你不符合，不可以点我" forState:UIControlStateNormal];

            }
        }];
        
        //将按钮的按下时间进行绑定
        [[button rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
            //将按钮执行的方法放置这里面
            
            UIAlertView * alertView = [[UIAlertView alloc]initWithTitle:@"恭喜你" message:@"看来你是真心爱刘力，想成为神仙么？" delegate:self cancelButtonTitle:@"想" otherButtonTitles:@"不想", nil];
            [alertView show];
            [alertView.rac_buttonClickedSignal subscribeNext:^(NSNumber *x) {
                if ([x isEqualToNumber:[NSNumber numberWithInteger:0]]) {
                    //这里点了第0个按钮
 
                    UIAlertView * alertViewOne = [[UIAlertView alloc]initWithTitle:@"你已经成为神仙了" message:@"你回家看看你床底下，多了500万，赏给你的" delegate:self cancelButtonTitle:@"哎呀，我回家了" otherButtonTitles:nil, nil];
                    [alertViewOne show];

                }else
                {
                    //这里点了第一个按钮
                    UIAlertView * alertViewTwo = [[UIAlertView alloc]initWithTitle:@"你不想当神仙?!!" message:@"你看看你的皮夹，没钱了吧！我变没了！" delegate:self cancelButtonTitle:@"我知道错了" otherButtonTitles:nil, nil];
                    [alertViewTwo show];

                }
            }];
        }];


    }
    
    
    // Configure the cell...
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100;
}

#pragma mark- 创建输入框
-(UITextField*)creatTextFieldWithView:(UIView*)view WithPlaceHolderStr:(NSString*)placeHolderStr
{
    UITextField * field = [[UITextField alloc]initWithFrame:view.bounds];
//    field.borderStyle = UITextBorderStyleLine;
    field.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    field.leftViewMode=UITextFieldViewModeAlways;
    field.delegate = self;
    field.leftViewMode=UITextFieldViewModeAlways;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.placeholder = placeHolderStr;
    field.font = [UIFont systemFontOfSize:12];
    [view addSubview:field];
    
    return field;
    
}


#pragma mark- 创建imageview
-(UIImageView*)creatImageViewWithView:(UIView*)view
{
    UIImageView * imageView = [[UIImageView alloc]initWithFrame:CGRectMake(CGRectGetMinX(view.bounds), CGRectGetMinY(view.bounds), CGRectGetHeight(view.bounds), CGRectGetHeight(view.bounds))];
    
    return imageView;
    
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    
    return YES;
}




/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
