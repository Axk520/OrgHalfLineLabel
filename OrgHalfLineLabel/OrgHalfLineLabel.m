//
//  OrgHalfLineLabel.m
//  Unity-iPhone
//
//  Created by 66-admin on 2018/4/24.
//

#import "OrgHalfLineLabel.h"
#import <CoreText/CoreText.h>

@interface OrgHalfLineLabel()

@property (nonatomic, copy)   NSMutableAttributedString * attributedString;
@property (nonatomic, assign) BOOL isDisplay;
@property (nonatomic, assign) BOOL isText;

@end

@implementation OrgHalfLineLabel

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        _orgMargin = UIEdgeInsetsZero;
        _isDisplay = YES;
        _orgVerticalTextAlignment = OrgHLVerticalTextAlignmentTop;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        _orgMargin = UIEdgeInsetsZero;
        _isDisplay = YES;
        _orgVerticalTextAlignment = OrgHLVerticalTextAlignmentTop;
    }
    return self;
}

- (void)dealloc {
    
    _attributedString = nil;
    _orgTruncationEndAttributedString = nil;
}

- (void)drawTextInRect:(CGRect)rect {
    
    if (self.text.length == 0 && self.attributedText == nil) {
        return;
    }
    
    if (_isDisplay) {
        if (_isText) {
            self.attributedString = [self orgSetAttributedStringStyle:self.text];
        } else {
            self.attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        }
        _isDisplay = NO;
    }
    
    if (!_attributedString) {
        return;
    }
    
    CGRect drawRect = CGRectMake(_orgMargin.left, _orgMargin.top, self.bounds.size.width - _orgMargin.left - _orgMargin.right, self.bounds.size.height - _orgMargin.top - _orgMargin.bottom);
    CTFramesetterRef framesetter  = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attributedString);
    CGMutablePathRef forecastPath = CGPathCreateMutable();
    CGPathAddRect(forecastPath, NULL, drawRect);
    CTFrameRef forecastFrame   = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), forecastPath, NULL);
    CFArrayRef forecastLines   = CTFrameGetLines(forecastFrame);
    long forecastMaxLineNumber = (long)CFArrayGetCount(forecastLines);
    
    CGRect drawingRect = CGRectMake(drawRect.origin.x, drawRect.origin.y, drawRect.size.width, CGFLOAT_MAX);
    CGMutablePathRef textpath = CGPathCreateMutable();
    CGPathAddRect(textpath, NULL, drawingRect);
    CTFrameRef textFrame   = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), textpath, NULL);
    CFArrayRef textlines   = CTFrameGetLines(textFrame);
    long textMaxLineNumber = (long)CFArrayGetCount(textlines);
    
    long minLinesNumber = MIN(forecastMaxLineNumber, textMaxLineNumber);
    _orgDrawOfLines = (int)(self.numberOfLines == 0 ? minLinesNumber : MIN(minLinesNumber, self.numberOfLines));
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, - 1.0);
    
    CGPoint lineOrigins[_orgDrawOfLines];
    CTFrameGetLineOrigins(forecastFrame, CFRangeMake(0, _orgDrawOfLines), lineOrigins);
    
    for (int lineIndex = 0; lineIndex < _orgDrawOfLines; lineIndex ++) {
        CTLineRef line = CFArrayGetValueAtIndex(forecastLines, lineIndex);
        CGPoint lineOrigin;
        if (forecastMaxLineNumber >= _orgDrawOfLines && _orgVerticalTextAlignment != OrgHLVerticalTextAlignmentTop) {
            if (_orgVerticalTextAlignment == OrgHLVerticalTextAlignmentMiddle) {
                float topMargin = lineOrigins[_orgDrawOfLines - 1].y / 2.0;
                lineOrigin = lineOrigins[lineIndex];
                lineOrigin = CGPointMake(lineOrigin.x, lineOrigin.y - floorf(topMargin));
            } else if (_orgVerticalTextAlignment == OrgHLVerticalTextAlignmentBottom) {
                CGFloat ascent;
                CGFloat descent;
                CGFloat leading;
                CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
                lineOrigin = lineOrigins[_orgDrawOfLines - 1 - lineIndex];
                lineOrigin = CGPointMake(lineOrigin.x, (self.bounds.size.height - floorf(lineOrigin.y + ascent - descent)));
            }
        } else {
            lineOrigin = lineOrigins[lineIndex];
        }
        
        CTLineRef lastLine = nil;
        if (_orgDrawOfLines < textMaxLineNumber) {
            if (lineIndex == _orgDrawOfLines - 1) {
                CFRange range = CTLineGetStringRange(line);
                NSDictionary * attributes  = [_attributedString attributesAtIndex:range.location + range.length - 1 effectiveRange:NULL];
                NSAttributedString * token = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:attributes];
                if (_orgTruncationEndAttributedString != nil) {
                    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:token];
                    [attributedString appendAttributedString:_orgTruncationEndAttributedString];
                    token = attributedString;
                }
                CFAttributedStringRef tokenRef = (__bridge CFAttributedStringRef)token;
                CTLineRef truncationToken = CTLineCreateWithAttributedString(tokenRef);
                
                NSRange lastLineRange = NSMakeRange(range.location, 0);
                lastLineRange.length  = [_attributedString length] - lastLineRange.location;
                CFAttributedStringRef longString = (__bridge CFAttributedStringRef)[_attributedString attributedSubstringFromRange:lastLineRange];
                CTLineRef endLine = CTLineCreateWithAttributedString(longString);
                lastLine = CTLineCreateTruncatedLine(endLine, self.bounds.size.width - _orgLastLineRightIndent, kCTLineTruncationEnd, truncationToken);
                
                if (truncationToken) {
                    CFRelease(truncationToken);
                }
                if (endLine) {
                    CFRelease(endLine);
                }
            }
        }
        if (lastLine) {
            CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
            CTLineDraw(lastLine, context);
            CFRelease(lastLine);
        } else {
            CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
            CTLineDraw(line, context);
        }
    }
    
    UIGraphicsPushContext(context);
    CFRelease(textpath);
    CFRelease(textFrame);
    CFRelease(forecastFrame);
    CFRelease(forecastPath);
    CFRelease(framesetter);
}

- (NSMutableAttributedString *)orgSetAttributedStringStyle:(NSString *)string {
    
    if (!string) {
        return nil;
    }
    
    NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing      = (_orgLineSpacing > 0) ? _orgLineSpacing : 4;
    style.paragraphSpacing = 0;
    style.alignment     = self.textAlignment;
    style.lineBreakMode = NSLineBreakByCharWrapping;
    
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    NSDictionary * attributes = @{NSForegroundColorAttributeName : self.textColor,
                                  NSFontAttributeName : self.font,
                                  NSKernAttributeName : @(_orgCharSpacing),
                                  NSParagraphStyleAttributeName : style};
    [attributedString addAttributes:attributes range:NSMakeRange(0, [attributedString length])];
    
    return attributedString;
}

- (void)setText:(NSString *)text {
    
    self.isDisplay = YES;
    self.isText    = YES;
    [super setText:text];
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    
    self.isDisplay = YES;
    self.isText    = NO;
    [super setAttributedText:attributedText];
}

- (void)setTextColor:(UIColor *)textColor {
    
    self.isDisplay = YES;
    [super setTextColor:textColor];
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    
    self.isDisplay = YES;
    [super setTextAlignment:textAlignment];
}

- (void)setFont:(UIFont *)font {
    
    self.isDisplay = YES;
    [super setFont:font];
}

- (void)setOrgLineSpacing:(CGFloat)orgLineSpacing {
    
    self.isDisplay  = YES;
    _orgLineSpacing = orgLineSpacing;
    [self setNeedsDisplay];
}

- (void)setOrgCharSpacing:(CGFloat)orgCharSpacing {
    
    self.isDisplay  = YES;
    _orgCharSpacing = orgCharSpacing;
    [self setNeedsDisplay];
}

- (void)setOrgMargin:(UIEdgeInsets)orgMargin {
    
    _orgMargin = orgMargin;
    [self setNeedsDisplay];
}

- (void)setOrgVerticalTextAlignment:(OrgHLVerticalTextAlignment)orgVerticalTextAlignment {
    
    _orgVerticalTextAlignment = orgVerticalTextAlignment;
    [self setNeedsDisplay];
}

@end
