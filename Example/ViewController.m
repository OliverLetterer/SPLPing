//
//  SPLViewController.m
//  SPLPing
//
//  Created by Oliver Letterer on 05/10/2015.
//  Copyright (c) 2015 Oliver Letterer. All rights reserved.
//

#import "ViewController.h"

#import <SPLPing/SPLPing.h>

@interface ViewController ()

@end



@implementation ViewController

#pragma mark - setters and getters

#pragma mark - Initialization

- (instancetype)init
{
    if (self = [super init]) {

    }
    return self;
}

#pragma mark - View lifecycle

//- (void)loadView
//{
//    [super loadView];
//
//}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (NSUInteger)supportedInterfaceOrientations
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskAll;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

#pragma mark - Private category implementation ()

@end
