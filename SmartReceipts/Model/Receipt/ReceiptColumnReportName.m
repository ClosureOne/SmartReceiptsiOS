//
//  ReceiptColumnReportName.m
//  SmartReceipts
//
//  Created by Jaanus Siim on 24/04/15.
//  Copyright (c) 2015 Will Baumann. All rights reserved.
//

#import "ReceiptColumnReportName.h"
#import "WBReceipt.h"
#import "WBTrip.h"

@implementation ReceiptColumnReportName

- (NSString *)valueFromReceipt:(WBReceipt *)receipt inTrip:(WBTrip *)trip receiptIndex:(NSInteger)receiptIndex forCSV:(BOOL)forCSV {
    return [trip name];
}

@end
