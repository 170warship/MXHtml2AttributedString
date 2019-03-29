//
//  MXHtml2AttributedString.m
//  MXOLNetwork
//
//  Created by idol_ios on 2018/11/1.
//  Copyright © 2018年 idol_ios. All rights reserved.
//

#import "MXHtml2AttributedString.h"
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

#define  MXHtml2AttributedStringNormalFontSize (15)

@interface MXHtml2AttributedStringComponent:NSObject
@property (nonatomic, assign) NSUInteger componentIndex;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *tagLabel;
@property (nonatomic,copy) NSMutableDictionary *attributes;
@property (nonatomic, assign) NSUInteger position;
@end

@implementation MXHtml2AttributedStringComponent

@end


@interface MXHtml2AttributedStringExtractedComponent : NSObject
@property (nonatomic, strong) NSMutableArray *textComponents;
@property (nonatomic, copy) NSString *plainText;
@end

@implementation MXHtml2AttributedStringExtractedComponent

@end



@interface MXHtml2AttributedString()


- (void)applyItalicStyleToText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyBoldStyleToText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyBoldItalicStyleToText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyColor:(NSString*)value toText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applySingleUnderlineText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyDoubleUnderlineText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyUnderlineColor:(NSString*)value toText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyFontAttributes:(NSDictionary*)attributes toText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyParagraphStyleToText:(NSMutableAttributedString*)text attributes:(NSMutableDictionary*)attributes atPosition:(CFIndex)position withLength:(CFIndex)length;
-(void)applyLinkAttributes:(NSDictionary*)attirbutes toText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
@end


@implementation MXHtml2AttributedString


-(instancetype)init{
    
    if(self = [super init]){
      
        
    }
    
    return self;
}



+ (MXHtml2AttributedStringExtractedComponent*)extractTextStyleFromText:(NSString*)data paragraphReplacement:(NSString*)paragraphReplacement
{
    NSScanner *scanner = nil;
    NSString *text = nil;
    NSString *tag = nil;
    
    NSMutableArray *components = [NSMutableArray array];
    
    NSInteger last_position = 0;
    scanner = [NSScanner scannerWithString:data];
    while (![scanner isAtEnd])
    {
        [scanner scanUpToString:@"<" intoString:NULL];
        [scanner scanUpToString:@">" intoString:&text];
        
        NSString *delimiter = [NSString stringWithFormat:@"%@>", text];
        NSInteger position = [data rangeOfString:delimiter].location;
        if (position!=NSNotFound&&text)
        {
            if ([delimiter rangeOfString:@"<p"].location==0)
            {
                data = [data stringByReplacingOccurrencesOfString:delimiter withString:paragraphReplacement options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position+delimiter.length-last_position)];
            }
            else
            {
                data = [data stringByReplacingOccurrencesOfString:delimiter withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(last_position, position+delimiter.length-last_position)];
            }
            
            data = [data stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
            data = [data stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        }
        
        if ([text rangeOfString:@"</"].location==0)
        {
            // end of tag
            tag = [text substringFromIndex:2];
            if (position!=NSNotFound)
            {
                for (NSInteger i=[components count]-1; i>=0; i--)
                {
                    MXHtml2AttributedStringComponent *component = [components objectAtIndex:i];
                    if (component.text==nil && [component.tagLabel isEqualToString:tag])
                    {
                        NSString *text2 = [data substringWithRange:NSMakeRange(component.position, position-component.position)];
                        component.text = text2;
                        break;
                    }
                }
            }
        }
        else
        {
            // start of tag
            NSArray *textComponents = [[text substringFromIndex:1] componentsSeparatedByString:@" "];
            tag = [textComponents objectAtIndex:0];
            //NSLog(@"start of tag: %@", tag);
            NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
            for (NSUInteger i=1; i<[textComponents count]; i++)
            {
                NSArray *pair = [[textComponents objectAtIndex:i] componentsSeparatedByString:@"="];
                if ([pair count] > 0) {
                    NSString *key = [[pair objectAtIndex:0] lowercaseString];
                    
                    if ([pair count]>=2) {
                        // Trim " charactere
                        NSString *value = [[pair subarrayWithRange:NSMakeRange(1, [pair count] - 1)] componentsJoinedByString:@"="];
                        value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, 1)];
                        value = [value stringByReplacingOccurrencesOfString:@"\"" withString:@"" options:NSLiteralSearch range:NSMakeRange([value length]-1, 1)];
                        
                        [attributes setObject:value forKey:key];
                    } else if ([pair count]==1) {
                        [attributes setObject:key forKey:key];
                    }
                }
            }
            MXHtml2AttributedStringComponent *component = [[MXHtml2AttributedStringComponent alloc] init];
            component.position = position;
            component.tagLabel = tag;
            component.attributes = attributes;
  
            [components addObject:component];
        }
        last_position = position;
    }
    
    MXHtml2AttributedStringExtractedComponent* ec =[[MXHtml2AttributedStringExtractedComponent alloc] init];
    ec.textComponents = components;
    ec.plainText = data;
    return ec;
}




- (NSMutableAttributedString*)translateText:(NSString *)text
{
    text = [[text stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"] stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    
    if([text length] == 0){
        text = @"";
    }
    
    MXHtml2AttributedStringExtractedComponent *component = [MXHtml2AttributedString extractTextStyleFromText:text paragraphReplacement:@"\n"];
    
    
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:component.plainText?component.plainText:@""];
    

    NSMutableArray *textComponents =  component.textComponents;;
    
    
    for (MXHtml2AttributedStringComponent *component in textComponents)
    {
        NSUInteger index = [textComponents indexOfObject:component];
        component.componentIndex = index;
        
        if ([component.tagLabel caseInsensitiveCompare:@"i"] == NSOrderedSame)
        {
            // make font italic
            [self applyItalicStyleToText:attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"b"] == NSOrderedSame)
        {
            // make font bold
            [self applyBoldStyleToText:attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"bi"] == NSOrderedSame)
        {
            [self applyBoldItalicStyleToText:attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"a"] == NSOrderedSame)
        {
            [self applyLinkAttributes:component.attributes toText:attrString atPosition:component.position withLength:[component.text length]];
            [self applySingleUnderlineText:attrString atPosition:component.position withLength:[component.text length]];
            
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"u"] == NSOrderedSame || [component.tagLabel caseInsensitiveCompare:@"uu"] == NSOrderedSame)
        {
            // underline
            if ([component.tagLabel caseInsensitiveCompare:@"u"] == NSOrderedSame)
            {
                [self applySingleUnderlineText:attrString atPosition:component.position withLength:[component.text length]];
            }
            else if ([component.tagLabel caseInsensitiveCompare:@"uu"] == NSOrderedSame)
            {
                [self applyDoubleUnderlineText:attrString atPosition:component.position withLength:[component.text length]];
            }
            
            if ([component.attributes objectForKey:@"color"])
            {
                NSString *value = [component.attributes objectForKey:@"color"];
                [self applyUnderlineColor:value toText:attrString atPosition:component.position withLength:[component.text length]];
            }
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"font"] == NSOrderedSame)
        {
            [self applyFontAttributes:component.attributes toText:attrString atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"p"] == NSOrderedSame)
        {
            [self applyParagraphStyleToText:attrString attributes:component.attributes atPosition:component.position withLength:[component.text length]];
        }
        else if ([component.tagLabel caseInsensitiveCompare:@"center"] == NSOrderedSame)
        {
            [self applyCenterStyleToText:attrString attributes:component.attributes atPosition:component.position withLength:[component.text length]];
        }
    }
    
    
    return attrString;
    
}

#pragma mark -
#pragma mark styling

- (void)applyParagraphStyleToText:(NSMutableAttributedString*)text attributes:(NSMutableDictionary*)attributes atPosition:(CFIndex)position withLength:(CFIndex)length
{

    // direction
    NSWritingDirection direction = NSWritingDirectionLeftToRight;
    // leading
    CGFloat firstLineIndent = 0.0;
    CGFloat headIndent = 0.0;
    CGFloat tailIndent = 0.0;
    CGFloat lineHeightMultiple = 1.0;
    CGFloat maxLineHeight = 0;
    CGFloat minLineHeight = 0;
    CGFloat paragraphSpacing = 0.0;
    CGFloat paragraphSpacingBefore = 0.0;
    NSTextAlignment textAlignment = NSTextAlignmentLeft;
    NSLineBreakMode lineBreakMode = NSLineBreakByWordWrapping;
    CGFloat lineSpacing = 3;
    
    for (NSUInteger i=0; i<[[attributes allKeys] count]; i++)
    {
        NSString *key = [[attributes allKeys] objectAtIndex:i];
        id value = [attributes objectForKey:key];
        if ([key caseInsensitiveCompare:@"align"] == NSOrderedSame)
        {
            if ([value caseInsensitiveCompare:@"left"] == NSOrderedSame)
            {
                textAlignment = NSTextAlignmentLeft;
            }
            else if ([value caseInsensitiveCompare:@"right"] == NSOrderedSame)
            {
                textAlignment = NSTextAlignmentRight;
            }
            else if ([value caseInsensitiveCompare:@"justify"] == NSOrderedSame)
            {
                textAlignment = NSTextAlignmentJustified;
            }
            else if ([value caseInsensitiveCompare:@"center"] == NSOrderedSame)
            {
                textAlignment = NSTextAlignmentCenter;
            }
        }
        else if ([key caseInsensitiveCompare:@"indent"] == NSOrderedSame)
        {
            firstLineIndent = [value floatValue];
        }
        else if ([key caseInsensitiveCompare:@"linebreakmode"] == NSOrderedSame)
        {
            if ([value caseInsensitiveCompare:@"wordwrap"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByWordWrapping;
            }
            else if ([value caseInsensitiveCompare:@"charwrap"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByCharWrapping;
            }
            else if ([value caseInsensitiveCompare:@"clipping"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByClipping;
            }
            else if ([value caseInsensitiveCompare:@"truncatinghead"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByTruncatingHead;
            }
            else if ([value caseInsensitiveCompare:@"truncatingtail"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByTruncatingTail;
            }
            else if ([value caseInsensitiveCompare:@"truncatingmiddle"] == NSOrderedSame)
            {
                lineBreakMode = NSLineBreakByTruncatingMiddle;
            }
        }
    }
    
    
    
    
    NSMutableParagraphStyle *paragraphStyle = nil;
    
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    [paragraphStyle setAlignment:textAlignment];
    [paragraphStyle setLineBreakMode:lineBreakMode];
    [paragraphStyle setBaseWritingDirection:direction];
    [paragraphStyle setLineSpacing:lineSpacing];
    [paragraphStyle setFirstLineHeadIndent:firstLineIndent];
    [paragraphStyle setHeadIndent:headIndent];
    [paragraphStyle setTailIndent:tailIndent];
    [paragraphStyle setLineHeightMultiple:lineHeightMultiple];
    [paragraphStyle setMaximumLineHeight:maxLineHeight];
    [paragraphStyle setMinimumLineHeight:minLineHeight];
    [paragraphStyle setParagraphSpacing:paragraphSpacing];
    [paragraphStyle setParagraphSpacingBefore:paragraphSpacingBefore];
    
    
    [text setAttributes:@{NSParagraphStyleAttributeName:paragraphStyle} range:NSMakeRange(position, length)];
}

- (void)applyCenterStyleToText:(NSMutableAttributedString*)text attributes:(NSMutableDictionary*)attributes atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    
    
    
    NSMutableParagraphStyle *paragraphStyle = nil;
    
    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
    [paragraphStyle setAlignment:NSTextAlignmentLeft];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    [paragraphStyle setBaseWritingDirection:NSWritingDirectionLeftToRight];
    [paragraphStyle setLineSpacing:3];
    [paragraphStyle setFirstLineHeadIndent:0];
    [paragraphStyle setHeadIndent:0];
    [paragraphStyle setTailIndent:0];
    [paragraphStyle setLineHeightMultiple:1.0];
    [paragraphStyle setMaximumLineHeight:0];
    [paragraphStyle setMinimumLineHeight:0];
    [paragraphStyle setParagraphSpacing:0];
    [paragraphStyle setParagraphSpacingBefore:0];
    
    [text setAttributes:@{NSParagraphStyleAttributeName:paragraphStyle} range:NSMakeRange(position, length)];
    
    
}

- (void)applySingleUnderlineText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    [text setAttributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)} range:NSMakeRange(position, length)];
}

- (void)applyDoubleUnderlineText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    
    [text setAttributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleDouble)} range:NSMakeRange(position, length)];
}

- (void)applyItalicStyleToText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{

    UIFont* font = [text attribute:NSFontAttributeName atIndex:position longestEffectiveRange:NULL inRange:NSMakeRange(position, 1)];
    
    [text setAttributes:@{NSFontAttributeName:[UIFont italicSystemFontOfSize:[font pointSize]]} range:NSMakeRange(position, length)];
    
}

- (void)applyFontAttributes:(NSDictionary*)attributes toText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    for (NSString *key in attributes)
    {
        NSString *value = [attributes objectForKey:key];
        value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
        
        if ([key caseInsensitiveCompare:@"color"] == NSOrderedSame)
        {
            [self applyColor:value toText:text atPosition:position withLength:length];
        }
        else if ([key caseInsensitiveCompare:@"stroke"] == NSOrderedSame)
        {
            
            [text setAttributes:@{NSStrokeWidthAttributeName:@([[attributes objectForKey:@"stroke"] intValue])} range:NSMakeRange(position, length)];
            
        }
        else if ([key caseInsensitiveCompare:@"kern"] == NSOrderedSame)
        {
            
             [text setAttributes:@{NSKernAttributeName:@([[attributes objectForKey:@"kern"] intValue])} range:NSMakeRange(position, length)];
            
            
        }
        else if ([key caseInsensitiveCompare:@"underline"] == NSOrderedSame)
        {
            int numberOfLines = [value intValue];
            if (numberOfLines==1)
            {
                [self applySingleUnderlineText:text atPosition:position withLength:length];
            }
            else if (numberOfLines==2)
            {
                [self applyDoubleUnderlineText:text atPosition:position withLength:length];
            }
        }
        else if ([key caseInsensitiveCompare:@"style"] == NSOrderedSame)
        {
            if ([value caseInsensitiveCompare:@"bold"] == NSOrderedSame)
            {
                [self applyBoldStyleToText:text atPosition:position withLength:length];
            }
            else if ([value caseInsensitiveCompare:@"italic"] == NSOrderedSame)
            {
                [self applyItalicStyleToText:text atPosition:position withLength:length];
            }
        }
    }
    
    UIFont *font = nil;
    if ([attributes objectForKey:@"face"] && [attributes objectForKey:@"size"])
    {
        NSString *fontName = [attributes objectForKey:@"face"];
        fontName = [fontName stringByReplacingOccurrencesOfString:@"'" withString:@""];
        font = [UIFont fontWithName:fontName size:[[attributes objectForKey:@"size"] intValue]];
    }
    else if ([attributes objectForKey:@"face"] && ![attributes objectForKey:@"size"])
    {
        NSString *fontName = [attributes objectForKey:@"face"];
        fontName = [fontName stringByReplacingOccurrencesOfString:@"'" withString:@""];
        font = [UIFont fontWithName:fontName size:MXHtml2AttributedStringNormalFontSize];
    }
    else if (![attributes objectForKey:@"face"] && [attributes objectForKey:@"size"])
    {
        UIFont* defaultFont = [UIFont systemFontOfSize:MXHtml2AttributedStringNormalFontSize];
        
        font = [UIFont fontWithName:[defaultFont fontName] size:[[attributes objectForKey:@"size"] intValue]];
    }
    if (font)
    {
        [text setAttributes:@{NSFontAttributeName:font} range:NSMakeRange(position, length)];
    }
}

- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef boldFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontBoldTrait, kCTFontBoldTrait);
    if (!boldFontRef) {
        //fallback to system bold font
        UIFont *font = [UIFont boldSystemFontOfSize:CTFontGetSize(actualFontRef)];
        boldFontRef = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
    }
    CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, boldFontRef);
    CFRelease(boldFontRef);
}

- (void)applyBoldItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef boldItalicFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontBoldTrait | kCTFontItalicTrait , kCTFontBoldTrait | kCTFontItalicTrait);
    
    [[UIFont alloc] ini]
    
    
    if (!boldItalicFontRef) {
        //try fallback to system boldItalic font
        UIFont* defaultFont = [UIFont systemFontOfSize:MXHtml2AttributedStringNormalFontSize];
        
        NSString *fontName = [NSString stringWithFormat:@"%@-BoldOblique", defaultFont.fontName];
        boldItalicFontRef = CTFontCreateWithName ((__bridge CFStringRef)fontName, [defaultFont pointSize], NULL);
    }
    
    if (boldItalicFontRef) {
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, boldItalicFontRef);
        CFRelease(boldItalicFontRef);
    }
    
}

- (void)applyColor:(NSString*)value toText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    
    if ([value rangeOfString:@"#"].location==0)
    {
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        UIColor *color = [self colorForHex:value];
        [text setAttributes:@{NSForegroundColorAttributeName:color} range:NSMakeRange(position, length)];
        
    } else {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        if ([UIColor respondsToSelector:colorSel]) {
            UIColor *color = [UIColor performSelector:colorSel];
            [text setAttributes:@{NSForegroundColorAttributeName:color} range:NSMakeRange(position, length)];
        }
    }
}

- (void)applyUnderlineColor:(NSString*)value toText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    
    value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
    if ([value rangeOfString:@"#"].location==0) {
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        
        UIColor *color = [self colorForHex:value];
        
        [text setAttributes:@{NSUnderlineColorAttributeName:color} range:NSMakeRange(position, length)];
        
    }
    else
    {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        if ([UIColor respondsToSelector:colorSel]) {
            UIColor *color = [UIColor performSelector:colorSel];
            [text setAttributes:@{NSUnderlineColorAttributeName:color} range:NSMakeRange(position, length)];
        }
    }
    
}

-(void)applyLinkAttributes:(NSDictionary*)attirbutes toText:(NSMutableAttributedString*)text atPosition:(NSUInteger)position withLength:(NSUInteger)length{
    
    
    NSString* href = [attirbutes objectForKey:@"href"];
    
    href = [href stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'"]];
    
    if([href isKindOfClass:[NSString class]]){
        NSMutableAttributedString* attri = text;
        
        [attri addAttribute:NSLinkAttributeName
                      value:href
                      range:NSMakeRange(position, length)];
    }
    
}

#pragma mark - other
- (UIColor*)colorForHex:(NSString *)hexColor
{
    hexColor = [[hexColor stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet]
                 ] uppercaseString];
    
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    NSString *rString = [hexColor substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [hexColor substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [hexColor substringWithRange:range];
    
    // Scan values
    unsigned int r = 0, g = 0, b = 0;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:(float) r / 255.0f green:(float) g / 255.0f blue:(float) b / 255.0f alpha:1.0];
    
    
}


@end
