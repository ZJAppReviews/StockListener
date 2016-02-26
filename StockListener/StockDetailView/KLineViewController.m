//
//  KLineChartViewController.m
//  StockListener
//
//  Created by Guozhen Li on 1/11/16.
//  Copyright © 2016 Guangzhen Li. All rights reserved.
//

#import "KLineViewController.h"
#import "StockKDJViewController.h"
#import "PNLineChartView.h"
#import "PNPlot.h"
#import "KLineSettingViewController.h"

@interface KLineViewController() {
    PNLineChartView *kLineChartView;
    UIView* parentView;
    UIButton* infoButton;
    UIButton* lineButton1;
    UIButton* lineButton2;
}

@end
@implementation KLineViewController

-(id) initWithParentView:(UIView*)view {
    if (self = [super init]) {
        parentView = view;
        kLineChartView = [[PNLineChartView alloc] init];
        [kLineChartView setBackgroundColor:[UIColor whiteColor]];
        [parentView addSubview:kLineChartView];
        [kLineChartView setYAxisPercentage:YES];
//        infoButton = [[UIButton alloc] init];
        infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoButton addTarget:self action:@selector(infoClicked:) forControlEvents:UIControlEventTouchUpInside];
//        [infoButton setImage:[UIImage imageNamed:@"setting_small"] forState:UIControlStateNormal];
        [parentView addSubview:infoButton];
        
        lineButton1 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        [lineButton1 setImage:[UIImage imageNamed:@"selection_normal.png"] forState:UIControlStateNormal];
        [lineButton1 addTarget:self action:@selector(dragMoving:withEvent: )
              forControlEvents: UIControlEventTouchDragInside];
        [parentView addSubview:lineButton1];

        lineButton2 = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        [lineButton2 addTarget:self action:@selector(dragMoving:withEvent: )
              forControlEvents: UIControlEventTouchDragInside];
        [lineButton2 setImage:[UIImage imageNamed:@"selection_normal.png"] forState:UIControlStateNormal];
        [parentView addSubview:lineButton2];
        
        [lineButton1 setHidden:YES];
        [lineButton2 setHidden:YES];
        
        __weak KLineViewController* weakSelf = self;
        [kLineChartView setOnScroll:^(NSInteger delta, BOOL finished) {
            if (weakSelf.onScroll != nil) {
                weakSelf.onScroll(delta, finished);
            }
        }];
        [kLineChartView setOnScale:^(float zoom, BOOL finished) {
            if (weakSelf.onScale != nil) {
                weakSelf.onScale(zoom, finished);
            }
        }];
    }
    return self;
}

-(void) infoClicked:(id)btn {
    KLineSettingViewController* controller = [[KLineSettingViewController alloc] init];
    [controller setStockInfo:self.stockInfo];
    [self.viewController presentViewController:controller animated:YES completion:nil];
}

- (void) dragMoving: (UIControl *) c withEvent:ev
{
    c.center = [[[ev allTouches] anyObject] locationInView:parentView];
}

-(void) setPriceMark:(float)priceMark {
    [kLineChartView setMarkY:priceMark];
}

-(void) setPriceMarkColor:(UIColor*)color {
    [kLineChartView setMarkYColor:color];
}

-(void) setPriceInfoStr:(NSString*)str {
    [kLineChartView setInfoStr:str];
}

-(void) setFrame:(CGRect)rect {
    [kLineChartView setFrame: rect];
    CGRect rectInfo = infoButton.frame;
    rectInfo.origin.x = rect.origin.x+20;
    rectInfo.origin.y = rect.origin.y;
//    rectInfo.size.width = 20;
//    rectInfo.size.height = 20;
    [infoButton setFrame:rectInfo];
    
    CGRect rect2 = lineButton1.frame;
    rect2.origin.x = rect.size.width/3;
    rect2.origin.y = rect.size.height/2 + rect.origin.y;
    [lineButton1 setFrame:rect2];
    
    rect2 = lineButton2.frame;
    rect2.origin.x = rect.size.width/3 * 2;
    rect2.origin.y = rect.size.height/2 + rect.origin.y;
    [lineButton2 setFrame:rect2];
}

-(void) hideInfoButton {
    [infoButton setHidden:YES];
}

-(void) setSplitX:(NSInteger)x {
    kLineChartView.splitX = x;
}

-(void) clearPlot {
    [kLineChartView clearPlot];
    [kLineChartView setNeedsDisplay];
}

-(float) getPointerInterval {
    return kLineChartView.pointerInterval;
}

-(void) refresh:(float)lowest andHighest:(float)highest andDrawKLine:(BOOL)drawKLine {
//    NSMutableArray* cPriceArray = [[NSMutableArray alloc] init];
    NSMutableArray* ma5Array = [[NSMutableArray alloc] init];
    NSMutableArray* ma10Array = [[NSMutableArray alloc] init];
    NSMutableArray* ma20Array = [[NSMutableArray alloc] init];
    NSMutableArray* cArray = [[NSMutableArray alloc] init];
    for (NSInteger i = self.startIndex; i<[self.priceKValues count]; i++) {
        NSArray* array = [self.priceKValues objectAtIndex:i];
        if ([array count] != 4) {
            continue;
        }
        if (drawKLine == YES) {
            [cArray addObject:array];
        } else {
            NSNumber* number = [array objectAtIndex:2];
            [cArray addObject:number];
        }
        //MA5
        if (i-5 >= 0) {
            float average = 0;
            for (int j=0; j<5; j++) {
                NSArray* array = [self.priceKValues objectAtIndex:i-5+j];
                if ([array count] != 4) {
                    continue;
                }
                NSNumber* p = [array objectAtIndex:2];
                average += [p floatValue];
            }
            [ma5Array addObject:[NSNumber numberWithFloat:average/5]];
        } else {
            [ma5Array addObject:@"No"];
        }
        //MA10
        if (i-10 >= 0) {
            float average = 0;
            for (int j=0; j<10; j++) {
                NSArray* array = [self.priceKValues objectAtIndex:i-10+j];
                if ([array count] != 4) {
                    continue;
                }
                NSNumber* p = [array objectAtIndex:2];
                average += [p floatValue];
            }
            [ma10Array addObject:[NSNumber numberWithFloat:average/10]];
        } else {
            [ma10Array addObject:@"No"];
        }
        //MA20
        if (i-20 >= 0) {
            float average = 0;
            for (int j=0; j<20; j++) {
                NSArray* array = [self.priceKValues objectAtIndex:i-20+j];
                if ([array count] != 4) {
                    continue;
                }
                NSNumber* p = [array objectAtIndex:2];
                average += [p floatValue];
            }
            [ma20Array addObject:[NSNumber numberWithFloat:average/20]];
        } else {
            [ma20Array addObject:@"No"];
        }
    }

    //K line
    kLineChartView.max = highest;
    kLineChartView.min = lowest;
    
    NSInteger maxCount = [cArray count] + 1;
    kLineChartView.pointerInterval = (kLineChartView.frame.size.width - 20 - 1)/(maxCount-1);
    kLineChartView.xAxisInterval = (kLineChartView.frame.size.width - 20-1)/(maxCount-1);
    kLineChartView.horizontalLineInterval = (float)(kLineChartView.frame.size.height-1) / 5.0;
    if (highest == lowest) {
        kLineChartView.interval = 1;
    } else {
        kLineChartView.interval = (highest-lowest)/5.0;
    }
    float delta = (highest - lowest)/5.0;
    NSMutableArray* array = [[NSMutableArray alloc] init];
    for (int i=0; i<6; i++) {
        [array addObject:[NSNumber numberWithFloat:lowest+delta*i]];
    }
    if (lowest > 3) {
        kLineChartView.floatNumberFormatterString = @"%.2f";
    } else {
        kLineChartView.floatNumberFormatterString = @"%.3f";
    }
    kLineChartView.yAxisValues = array;
    kLineChartView.numberOfVerticalElements = 6;
    kLineChartView.axisLeftLineWidth = LEFT_PADDING;
    
    [kLineChartView clearPlot];
    
    PNPlot *plot1 = [[PNPlot alloc] init];
    plot1.plottingValues = [cArray mutableCopy];
    plot1.lineColor = [UIColor redColor];
    plot1.lineWidth = 2;
    plot1.isKLine = drawKLine;
    [kLineChartView addPlot:plot1];
    
    PNPlot *plot2 = [[PNPlot alloc] init];
    plot2.plottingValues = [ma5Array mutableCopy];
    plot2.lineColor = [UIColor blackColor];
    plot2.lineWidth = 1;
    [kLineChartView addPlot:plot2];
    float price = 0;
    if ([ma5Array count] != 0) {
        price = [[ma5Array lastObject] floatValue];
        if (price >= 3) {
            self.fiveAPrice.text = [NSString stringWithFormat:@"%.2f", price];
        } else {
            self.fiveAPrice.text = [NSString stringWithFormat:@"%.3f", price];
        }
    }
    
    PNPlot *plot3 = [[PNPlot alloc] init];
    plot3.plottingValues = [ma10Array mutableCopy];
    plot3.lineColor = [UIColor blueColor];
    plot3.lineWidth = 1;
    [kLineChartView addPlot:plot3];
    if ([ma10Array count] != 0) {
        price = [[ma10Array lastObject] floatValue];
        if (price >= 3) {
            self.tenAPrice.text = [NSString stringWithFormat:@"%.2f", price];
        } else {
            self.tenAPrice.text = [NSString stringWithFormat:@"%.3f", price];
        }
    }
    
    PNPlot *plot4 = [[PNPlot alloc] init];
    plot4.plottingValues = [ma20Array mutableCopy];
    plot4.lineColor = [UIColor orangeColor];
    plot4.lineWidth = 1;
    [kLineChartView addPlot:plot4];
    if ([ma20Array count] != 0) {
        price = [[ma20Array lastObject] floatValue];
        if (price >= 3) {
            self.twentyAPrice.text = [NSString stringWithFormat:@"%.2f", price];
        } else {
            self.twentyAPrice.text = [NSString stringWithFormat:@"%.3f", price];
        }
    }

    [kLineChartView setNeedsDisplay];
}

-(void) startEditLine {
    [lineButton1 setHidden:NO];
    [lineButton2 setHidden:NO];
}

-(void) endEditLine {
    [lineButton1 setHidden:YES];
    [lineButton2 setHidden:YES];
}

@end
