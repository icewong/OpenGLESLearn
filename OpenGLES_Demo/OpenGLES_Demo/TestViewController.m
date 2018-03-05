//
//  TestViewController.m
//  OpenGLES_Demo
//
//  Created by WangBing on 2018/2/2.
//  Copyright © 2018年 SkyLight. All rights reserved.
//

#import "TestViewController.h"
#import "GLViewController.h"
#import "GuestureViewController.h"
@interface TestViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic)UITableView * tableView;
@property (strong, nonatomic)NSMutableArray * dataArray;
@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configSubViews];
    [self layoutSubViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)configSubViews{
    
    //配置子视图
    [self.view addSubview:self.tableView];
}

- (void)layoutSubViews{
    
    self.tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
}


#pragma mark - UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"abcCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"abcCell"];
    }
    NSString *title = @"";
    if (indexPath.row == 0)
    {
        title = @"GL_TEXTURE_2D 渲染";
        
    }else if (indexPath.row == 1 == 1) {
        title = @"手势滑动";
    }
    else
    {

    }
    cell.textLabel.text = title;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return 2;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
            GLViewController *testVC = [[GLViewController alloc]init];
            [self.navigationController pushViewController:testVC animated:NO];
        }
            break;
        case 1:
        {
            GuestureViewController *testVC = [[GuestureViewController alloc]init];
            [self.navigationController pushViewController:testVC animated:NO];
        }

            break;
        default:
            break;
    }
}


- (NSMutableArray *)dataArray{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}
- (UITableView *)tableView{
    
    if (_tableView == nil) {
        _tableView = [UITableView new];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor orangeColor];
        
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"abcCell"];
    }
    return _tableView;
}

@end
