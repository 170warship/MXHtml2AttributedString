//
//  MXHtml2AttributedString.m
//  MXOLNetwork
//
//  Created by idol_ios on 2018/11/1.
//  Copyright © 2018年 idol_ios. All rights reserved.
//

#import "MXHtml2AttributedString.h"

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


- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyBoldStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyBoldItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applySingleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyDoubleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyUnderlineColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyFontAttributes:(NSDictionary*)attributes toText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(CFIndex)position withLength:(CFIndex)length;
-(void)applyLinkAttributes:(NSDictionary*)attirbutes toText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length;
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
    
    CFStringRef string = (__bridge CFStringRef)(component.plainText?component.plainText:@"");
    CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString (attrString, CFRangeMake(0, 0), string);
    

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
    
    NSMutableAttributedString* nsAttr = CFBridgingRelease(attrString);
    
    return nsAttr;
    
}

#pragma mark -
#pragma mark styling

- (void)applyParagraphStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(CFIndex)position withLength:(CFIndex)length
{
    CFMutableDictionaryRef styleDict = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );
    
    // direction
    CTWritingDirection direction = kCTWritingDirectionLeftToRight;
    // leading
    CGFloat firstLineIndent = 0.0;
    CGFloat headIndent = 0.0;
    CGFloat tailIndent = 0.0;
    CGFloat lineHeightMultiple = 1.0;
    CGFloat maxLineHeight = 0;
    CGFloat minLineHeight = 0;
    CGFloat paragraphSpacing = 0.0;
    CGFloat paragraphSpacingBefore = 0.0;
    CTTextAlignment textAlignment = kCTTextAlignmentLeft;
    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    CGFloat lineSpacing = 3;
    
    for (NSUInteger i=0; i<[[attributes allKeys] count]; i++)
    {
        NSString *key = [[attributes allKeys] objectAtIndex:i];
        id value = [attributes objectForKey:key];
        if ([key caseInsensitiveCompare:@"align"] == NSOrderedSame)
        {
            if ([value caseInsensitiveCompare:@"left"] == NSOrderedSame)
            {
                textAlignment = kCTLeftTextAlignment;
            }
            else if ([value caseInsensitiveCompare:@"right"] == NSOrderedSame)
            {
                textAlignment = kCTRightTextAlignment;
            }
            else if ([value caseInsensitiveCompare:@"justify"] == NSOrderedSame)
            {
                textAlignment = kCTJustifiedTextAlignment;
            }
            else if ([value caseInsensitiveCompare:@"center"] == NSOrderedSame)
            {
                textAlignment = kCTCenterTextAlignment;
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
                lineBreakMode = kCTLineBreakByWordWrapping;
            }
            else if ([value caseInsensitiveCompare:@"charwrap"] == NSOrderedSame)
            {
                lineBreakMode = kCTLineBreakByCharWrapping;
            }
            else if ([value caseInsensitiveCompare:@"clipping"] == NSOrderedSame)
            {
                lineBreakMode = kCTLineBreakByClipping;
            }
            else if ([value caseInsensitiveCompare:@"truncatinghead"] == NSOrderedSame)
            {
                lineBreakMode = kCTLineBreakByTruncatingHead;
            }
            else if ([value caseInsensitiveCompare:@"truncatingtail"] == NSOrderedSame)
            {
                lineBreakMode = kCTLineBreakByTruncatingTail;
            }
            else if ([value caseInsensitiveCompare:@"truncatingmiddle"] == NSOrderedSame)
            {
                lineBreakMode = kCTLineBreakByTruncatingMiddle;
            }
        }
    }
    
    CTParagraphStyleSetting theSettings[] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
        { kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode  },
        { kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(CTWritingDirection), &direction },
        { kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(CGFloat), &lineSpacing }, // leading
        { kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(CGFloat), &lineSpacing }, // leading
        { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
        { kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent },
        { kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &tailIndent },
        { kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeightMultiple },
        { kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &maxLineHeight },
        { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minLineHeight },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing },
        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore }
    };
    
    
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, sizeof(theSettings) / sizeof(CTParagraphStyleSetting));
    CFDictionaryAddValue( styleDict, kCTParagraphStyleAttributeName, theParagraphRef );
    
    CFAttributedStringSetAttributes( text, CFRangeMake(position, length), styleDict, 0 );
    CFRelease(theParagraphRef);
    CFRelease(styleDict);
}

- (void)applyCenterStyleToText:(CFMutableAttributedStringRef)text attributes:(NSMutableDictionary*)attributes atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    CFMutableDictionaryRef styleDict = ( CFDictionaryCreateMutable( (0), 0, (0), (0) ) );
    
    // direction
    CTWritingDirection direction = kCTWritingDirectionLeftToRight;
    // leading
    CGFloat firstLineIndent = 0.0;
    CGFloat headIndent = 0.0;
    CGFloat tailIndent = 0.0;
    CGFloat lineHeightMultiple = 1.0;
    CGFloat maxLineHeight = 0;
    CGFloat minLineHeight = 0;
    CGFloat paragraphSpacing = 0.0;
    CGFloat paragraphSpacingBefore = 0.0;
    //int textAlignment = _textAlignment;
    //int lineBreakMode = _lineBreakMode;
    //int lineSpacing = (int)_lineSpacing;
    
    CTTextAlignment textAlignment = kCTTextAlignmentLeft;
    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    CGFloat lineSpacing = 3;
    
    textAlignment = kCTCenterTextAlignment;
    
    CTParagraphStyleSetting theSettings[] =
    {
        { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &textAlignment },
        { kCTParagraphStyleSpecifierLineBreakMode, sizeof(CTLineBreakMode), &lineBreakMode  },
        { kCTParagraphStyleSpecifierBaseWritingDirection, sizeof(CTWritingDirection), &direction },
        //{ kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing },
        //{ kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
        
        { kCTParagraphStyleSpecifierMinimumLineSpacing, sizeof(CGFloat), &lineSpacing }, // leading
        { kCTParagraphStyleSpecifierMaximumLineSpacing, sizeof(CGFloat), &lineSpacing }, // leading
        { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineIndent },
        
        { kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent },
        { kCTParagraphStyleSpecifierTailIndent, sizeof(CGFloat), &tailIndent },
        { kCTParagraphStyleSpecifierLineHeightMultiple, sizeof(CGFloat), &lineHeightMultiple },
        { kCTParagraphStyleSpecifierMaximumLineHeight, sizeof(CGFloat), &maxLineHeight },
        { kCTParagraphStyleSpecifierMinimumLineHeight, sizeof(CGFloat), &minLineHeight },
        { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing },
        { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore }
    };
    
    CTParagraphStyleRef theParagraphRef = CTParagraphStyleCreate(theSettings, sizeof(theSettings) / sizeof(CTParagraphStyleSetting));
    CFDictionaryAddValue( styleDict, kCTParagraphStyleAttributeName, theParagraphRef );
    
    CFAttributedStringSetAttributes( text, CFRangeMake(position, length), styleDict, 0 );
    CFRelease(theParagraphRef);
    CFRelease(styleDict);
}

- (void)applySingleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTUnderlineStyleAttributeName,  (__bridge CFNumberRef)[NSNumber numberWithInt:kCTUnderlineStyleSingle]);
}

- (void)applyDoubleUnderlineText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTUnderlineStyleAttributeName,  (__bridge CFNumberRef)[NSNumber numberWithInt:kCTUnderlineStyleDouble]);
}

- (void)applyItalicStyleToText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    CFTypeRef actualFontRef = CFAttributedStringGetAttribute(text, position, kCTFontAttributeName, NULL);
    CTFontRef italicFontRef = CTFontCreateCopyWithSymbolicTraits(actualFontRef, 0.0, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
    if (!italicFontRef) {
        //fallback to system italic font
        UIFont *font = [UIFont italicSystemFontOfSize:CTFontGetSize(actualFontRef)];
        italicFontRef = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
    }
    CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, italicFontRef);
    CFRelease(italicFontRef);
}

- (void)applyFontAttributes:(NSDictionary*)attributes toText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
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
            CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTStrokeWidthAttributeName, (__bridge CFTypeRef)([NSNumber numberWithFloat:[[attributes objectForKey:@"stroke"] intValue]]));
        }
        else if ([key caseInsensitiveCompare:@"kern"] == NSOrderedSame)
        {
            CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTKernAttributeName, (__bridge CFTypeRef)([NSNumber numberWithFloat:[[attributes objectForKey:@"kern"] intValue]]));
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
        CTFontRef customFont = CTFontCreateWithName ((__bridge CFStringRef)[font fontName], [font pointSize], NULL);
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length), kCTFontAttributeName, customFont);
        CFRelease(customFont);
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

- (void)applyColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    
    if ([value rangeOfString:@"#"].location==0)
    {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@""];
        NSArray *colorComponents = [self colorForHex:value];
        CGFloat components[] = { [[colorComponents objectAtIndex:0] floatValue] , [[colorComponents objectAtIndex:1] floatValue] , [[colorComponents objectAtIndex:2] floatValue] , [[colorComponents objectAtIndex:3] floatValue] };
        CGColorRef color = CGColorCreate(rgbColorSpace, components);
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length),kCTForegroundColorAttributeName, color);
        CFRelease(color);
        CGColorSpaceRelease(rgbColorSpace);
    } else {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        UIColor *_color = nil;
        if ([UIColor respondsToSelector:colorSel]) {
            _color = [UIColor performSelector:colorSel];
            CGColorRef color = [_color CGColor];
            CFAttributedStringSetAttribute(text, CFRangeMake(position, length),kCTForegroundColorAttributeName, color);
        }
    }
}

- (void)applyUnderlineColor:(NSString*)value toText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length
{
    
    value = [value stringByReplacingOccurrencesOfString:@"'" withString:@""];
    if ([value rangeOfString:@"#"].location==0) {
        CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
        value = [value stringByReplacingOccurrencesOfString:@"#" withString:@"0x"];
        NSArray *colorComponents = [self colorForHex:value];
        CGFloat components[] = { [[colorComponents objectAtIndex:0] floatValue] , [[colorComponents objectAtIndex:1] floatValue] , [[colorComponents objectAtIndex:2] floatValue] , [[colorComponents objectAtIndex:3] floatValue] };
        CGColorRef color = CGColorCreate(rgbColorSpace, components);
        CFAttributedStringSetAttribute(text, CFRangeMake(position, length),kCTUnderlineColorAttributeName, color);
        CGColorRelease(color);
        CGColorSpaceRelease(rgbColorSpace);
    }
    else
    {
        value = [value stringByAppendingString:@"Color"];
        SEL colorSel = NSSelectorFromString(value);
        if ([UIColor respondsToSelector:colorSel]) {
            UIColor *_color = [UIColor performSelector:colorSel];
            CGColorRef color = [_color CGColor];
            CFAttributedStringSetAttribute(text, CFRangeMake(position, length),kCTUnderlineColorAttributeName, color);
            //CGColorRelease(color);
        }
    }
    
}

-(void)applyLinkAttributes:(NSDictionary*)attirbutes toText:(CFMutableAttributedStringRef)text atPosition:(NSUInteger)position withLength:(NSUInteger)length{
    
    
    NSString* href = [attirbutes objectForKey:@"href"];
    
    href = [href stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'"]];
    
    if([href isKindOfClass:[NSString class]]){
        NSMutableAttributedString* attri = (__bridge NSMutableAttributedString*)text;
        
        [attri addAttribute:NSLinkAttributeName
                      value:href
                      range:NSMakeRange(position, length)];
    }
    
}

#pragma mark - other
- (NSArray*)colorForHex:(NSString *)hexColor
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
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    NSArray *components = [NSArray arrayWithObjects:[NSNumber numberWithFloat:((float) r / 255.0f)],[NSNumber numberWithFloat:((float) g / 255.0f)],[NSNumber numberWithFloat:((float) b / 255.0f)],[NSNumber numberWithFloat:1.0],nil];
    return components;
    
}


@end
