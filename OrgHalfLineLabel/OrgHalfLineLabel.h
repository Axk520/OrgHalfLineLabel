//
//  OrgHalfLineLabel.h
//  Unity-iPhone
//
//  Created by 66-admin on 2018/4/24.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, OrgHLVerticalTextAlignment) {
    OrgHLVerticalTextAlignmentTop,
    OrgHLVerticalTextAlignmentMiddle,
    OrgHLVerticalTextAlignmentBottom
};

@interface OrgHalfLineLabel : UILabel

/**
 上下对齐方式
 */
@property (nonatomic, assign) OrgHLVerticalTextAlignment orgVerticalTextAlignment;

/**
 行间距
 */
@property (nonatomic, assign) CGFloat orgLineSpacing;

/**
 字间距
 */
@property (nonatomic, assign) CGFloat orgCharSpacing;

/**
 边距
 */
@property (nonatomic, assign) UIEdgeInsets orgMargin;

/**
 尾行右缩进
 */
@property (nonatomic, assign) CGFloat orgLastLineRightIndent;

/**
 尾行结束字符串
 */
@property (nonatomic, copy) NSAttributedString * orgTruncationEndAttributedString;

/**
 实际绘制的行数,当 numberOfLines == 0 时
 */
@property (nonatomic, assign, readonly) NSInteger orgDrawOfLines;

@end

