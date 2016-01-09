//
//  StockInfo.m
//  StockListener
//
//  Created by Guozhen Li on 12/8/15.
//  Copyright © 2015 Guangzhen Li. All rights reserved.
//

#import "StockInfo.h"

@interface StockInfo()
@end

@implementation StockInfo

@synthesize sid;
@synthesize name;

#define SID @"sid"
#define NAME @"name"
#define CURRENT_PRICE @"current_price"
#define CHANGE_RATE @"change_rate"
#define BUY_SELL_DIC @"buy_sell_dic"
#define UPDATE_DAY @"upreate_day"
#define FIVE_DAY_PRICE_HISTORY @"five_day_price_history"
#define FIVE_DAY_LAST_UPDAT_DAY @"five_day_update_day"
#define HUNDRED_DAY_PRICE_HISTORY @"hundred_day_price_history"
#define HUNDRED_DAY_UPDATE_DAY @"hundred_day_update_day"

- (id) init {
    if (self = [super init]) {
        self.name = @"-";
        self.sid = @"-";
        self.step = 0;
        self.changeRate = 0;
        self.speed = 0;
        self.openPrice = 0;
        self.lastDayPrice = 0;
        self.price = 0;
        self.todayHighestPrice = 0;
        self.todayLoestPrice = 0;
        self.dealCount = 0;
        self.dealTotalMoney = 0;
        self.buyOneCount = 0;
        self.buyOnePrice = 0;
        self.buyTwoCount = 0;
        self.buyTwoPrice = 0;
        self.buyThreeCount = 0;
        self.buyThreePrice = 0;
        self.buyFourCount = 0;
        self.buyFourPrice = 0;
        self.buyFiveCount = 0;
        self.buyFivePrice = 0;
        self.sellOneCount = 0;
        self.sellOnePrice = 0;
        self.sellTwoPrice = 0;
        self.sellTwoCount = 0;
        self.sellThreeCount = 0;
        self.sellThreePrice = 0;
        self.sellFourCount = 0;
        self.sellFourPrice = 0;
        self.sellFiveCount = 0;
        self.sellFivePrice = 0;
        self.updateDay = @"";
        self.updateTime = @"";
        self.buySellDic = [[NSMutableDictionary alloc] init];
        self.fiveDayPriceByMinutes = [[NSMutableArray alloc] init];
        self.fiveDayLastUpdateDay = @"";
        self.hundredDaysPrice = [[NSMutableArray alloc] init];
        self.hundredDayLastUpdateDay = @"";
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    StockInfo* info = [[StockInfo allocWithZone:zone] init];
    info.sid = [self.sid copy];
    info.name = [self.name copy];
    info.price = self.price;
    info.changeRate = self.changeRate;
    info.step = self.step;
    
    info.openPrice = self.openPrice;
    info.lastDayPrice = self.lastDayPrice;
    
    info.buySellDic = [self.buySellDic copy];
    info.todayPriceByMinutes = [self.todayPriceByMinutes copy];
    info.fiveDayPriceByMinutes = [self.fiveDayPriceByMinutes copy];
    info.fiveDayLastUpdateDay = [self.fiveDayLastUpdateDay copy];
    info.hundredDayLastUpdateDay = [self.hundredDayLastUpdateDay copy];
    info.hundredDaysPrice = [self.hundredDaysPrice copy];
    return info;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.sid forKey:SID];
    [aCoder encodeObject:self.name forKey:NAME];
    [aCoder encodeObject:self.updateDay forKey:UPDATE_DAY];
    if (self.buySellDic != nil) {
        [aCoder encodeObject:self.buySellDic forKey:BUY_SELL_DIC];
    }
    if (self.fiveDayLastUpdateDay != nil) {
        [aCoder encodeObject:self.fiveDayLastUpdateDay forKey:FIVE_DAY_LAST_UPDAT_DAY];
    }
    if (self.fiveDayPriceByMinutes != nil) {
        [aCoder encodeObject:self.fiveDayPriceByMinutes forKey:FIVE_DAY_PRICE_HISTORY];
    }
    if (self.hundredDaysPrice != nil) {
        [aCoder encodeObject:self.hundredDaysPrice forKey:HUNDRED_DAY_PRICE_HISTORY];
    }
    if (self.hundredDayLastUpdateDay != nil) {
        [aCoder encodeObject:self.hundredDayLastUpdateDay forKey:HUNDRED_DAY_UPDATE_DAY];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.sid = [aDecoder decodeObjectForKey:SID];
        self.name = [aDecoder decodeObjectForKey:NAME];
        self.buySellDic = [aDecoder decodeObjectForKey:BUY_SELL_DIC];
        self.updateDay = [aDecoder decodeObjectForKey:UPDATE_DAY];
        self.fiveDayLastUpdateDay = [aDecoder decodeObjectForKey:FIVE_DAY_LAST_UPDAT_DAY];
        self.fiveDayPriceByMinutes = [aDecoder decodeObjectForKey:FIVE_DAY_PRICE_HISTORY];
        self.hundredDayLastUpdateDay = [aDecoder decodeObjectForKey:HUNDRED_DAY_UPDATE_DAY];
        self.hundredDaysPrice = [aDecoder decodeObjectForKey:HUNDRED_DAY_PRICE_HISTORY];

        if (self.buySellDic == nil) {
            self.buySellDic = [[NSMutableDictionary alloc] init];
        }
        if (self.fiveDayLastUpdateDay == nil) {
            self.fiveDayLastUpdateDay = @"";
        }
        if (self.fiveDayPriceByMinutes == nil) {
            self.fiveDayPriceByMinutes = [[NSMutableArray alloc] init];
        }
        if (self.hundredDayLastUpdateDay == nil) {
            self.hundredDayLastUpdateDay = @"";
        }
        if (self.hundredDaysPrice == nil) {
            self.hundredDaysPrice = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

-(void) newPriceGot {
    if ([self.updateDay length] > 6 && [self.hundredDaysPrice count] > 0) {
        NSString* str = [self.updateDay stringByReplacingOccurrencesOfString:@"-" withString:@""];
        str = [str substringFromIndex:2];
        NSInteger latest = [str integerValue];
        NSInteger history = [self.hundredDayLastUpdateDay integerValue];
        if (latest - history == 0) {
            ////
            NSMutableArray* array = [self.hundredDaysPrice lastObject];
            ////
            [self.hundredDaysPrice removeLastObject];
            array = [[NSMutableArray alloc] init];
            [array addObject:[NSNumber numberWithFloat:self.todayHighestPrice]];
            [array addObject:[NSNumber numberWithFloat:self.price]];
            [array addObject:[NSNumber numberWithFloat:self.todayLoestPrice]];
            [self.hundredDaysPrice addObject:array];
        } else if (latest - history > 0) {
            NSMutableArray* array = [[NSMutableArray alloc] init];
            [array addObject:[NSNumber numberWithFloat:self.todayHighestPrice]];
            [array addObject:[NSNumber numberWithFloat:self.price]];
            [array addObject:[NSNumber numberWithFloat:self.todayLoestPrice]];
            [self.hundredDaysPrice addObject:array];
        }
    }
    
    // Store price
    NSArray* timeArray = [self.updateTime componentsSeparatedByString:@":"];
    if ([timeArray count] != 3) {
        return;
    }
    long hour = [[timeArray objectAtIndex:0] integerValue] ;
    long minute = [[timeArray objectAtIndex:1] integerValue];

    NSInteger index = 0;
    index = (hour - 9) * 60 + minute - 30;
    if (hour >= 13) {
        index -= 90;
    }
    index++;
    if ([self.todayPriceByMinutes count] == 0) {
        [self.todayPriceByMinutes addObject:[NSNumber numberWithFloat:self.price]];
        return;
    }
    if (index >=242) {
        return;
    }
    if (index >= [self.todayPriceByMinutes count]) {
        [self.todayPriceByMinutes addObject:[NSNumber numberWithFloat:self.price]];
        return;
    }
    [self.todayPriceByMinutes removeLastObject];
    [self.todayPriceByMinutes addObject:[NSNumber numberWithFloat:self.price]];
    /*
    long second = [[timeArray objectAtIndex:2] longLongValue];
    long totalSecond = hour * 60 * 60;
    totalSecond += (minute * 60);
    totalSecond += second;
    totalSecond -= (9*60*60 + 30*60);
    if (totalSecond < 0) {
        return;
    }
    if (totalSecond > (2*60*60)) {
        if (totalSecond < (3*60*60 + 30 *60)) {
            return;
        }
        totalSecond -= (60*60 + 30*60);
    }
    NSString* halfMinuteKey = [NSString stringWithFormat:@"%ld", totalSecond / 30];
    NSString* minuteKey = [NSString stringWithFormat:@"%ld", totalSecond / 60];
    NSString* fiveMinuteKey = [NSString stringWithFormat:@"%ld", totalSecond / (5 * 60)];
    NSLog(@"%@ %@ %@", halfMinuteKey, minuteKey, fiveMinuteKey);
    // Half minute data
    NSString* halfMinuteData = [self.priceHistoryHalfMinute valueForKey:halfMinuteKey];
    if (halfMinuteData != nil) {
        NSArray* prices = [halfMinuteData componentsSeparatedByString:@" "];
        if ([prices count] == 3) {
            float highP = [[prices objectAtIndex:0] floatValue];
            float lowP = [[prices objectAtIndex:2] floatValue];
            if (highP < self.price) {
                highP = self.price;
            }
            if (lowP > self.price) {
                lowP = self.price;
            }
            NSString* data = [NSString stringWithFormat:@"%f %f %f", highP, self.price, lowP];
            [self.priceHistoryHalfMinute setObject:data forKey:halfMinuteKey];
//            NSLog(@"%@", data);
        } else {
            halfMinuteData = nil;
        }
    }
    if (halfMinuteData == nil) {
        NSString* data = [NSString stringWithFormat:@"%f %f %f", self.price, self.price, self.price];
        [self.priceHistoryHalfMinute setObject:data forKey:halfMinuteKey];
//        NSLog(@"%@", data);
    }
    // minute data
    NSString* minuteData = [self.priceHistoryOneMinutes valueForKey:minuteKey];
    if (minuteData != nil) {
        NSArray* prices = [minuteData componentsSeparatedByString:@" "];
        if ([prices count] == 3) {
            float highP = [[prices objectAtIndex:0] floatValue];
            float lowP = [[prices objectAtIndex:2] floatValue];
            if (highP < self.price) {
                highP = self.price;
            }
            if (lowP > self.price) {
                lowP = self.price;
            }
            NSString* data = [NSString stringWithFormat:@"%f %f %f", highP, self.price, lowP];
            [self.priceHistoryOneMinutes setObject:data forKey:minuteKey];
//            NSLog(@"%@", data);
        } else {
            minuteData = nil;
        }
    }
    if (minuteData == nil) {
        NSString* data = [NSString stringWithFormat:@"%f %f %f", self.price, self.price, self.price];
        [self.priceHistoryOneMinutes setObject:data forKey:minuteKey];
//        NSLog(@"%@", data);
    }
    // Five minutes
    NSString* fiveMinuteData = [self.priceHistoryFiveMinutes valueForKey:fiveMinuteKey];
    if (fiveMinuteData != nil) {
        NSArray* prices = [fiveMinuteData componentsSeparatedByString:@" "];
        if ([prices count] == 3) {
            float highP = [[prices objectAtIndex:0] floatValue];
            float lowP = [[prices objectAtIndex:2] floatValue];
            if (highP < self.price) {
                highP = self.price;
            }
            if (lowP > self.price) {
                lowP = self.price;
            }
            NSString* data = [NSString stringWithFormat:@"%f %f %f", highP, self.price, lowP];
            [self.priceHistoryFiveMinutes setObject:data forKey:fiveMinuteKey];
//            NSLog(@"%@", data);
        } else {
            fiveMinuteData = nil;
        }
    }
    if (fiveMinuteData == nil) {
        NSString* data = [NSString stringWithFormat:@"%f %f %f", self.price, self.price, self.price];
        [self.priceHistoryFiveMinutes setObject:data forKey:fiveMinuteKey];
//        NSLog(@"%@", data);
    }
     */
}

@end
