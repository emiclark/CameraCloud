//
//  Comment.h
//  CameraAndCloud
//
//  Created by Emiko Clark on 3/3/17.
//  Copyright © 2017 Emiko Clark. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Comment : NSObject
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *text;

- (instancetype)initWithUsername: (NSString*) user andText: (NSString*) text;
@end
