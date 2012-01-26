//
//  NSAttributedString+FileWrapper.m
//  JAMultiTypeSavePanelControllerTest
//
//  Created by Jan on 26.01.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import "NSAttributedString+FileWrapper.h"

@implementation NSAttributedString (FileWrapper)

- (NSFileWrapper *)fileWrapperForDocumentType:(NSString *)documentType error:(NSError **)error;
{
    NSFileWrapper *wrapper = nil;
    NSRange range = {0, self.length};
    NSDictionary *attributesDict = [NSDictionary dictionaryWithObject:documentType forKey:NSDocumentTypeDocumentAttribute];
    
    if (documentType == NSRTFDTextDocumentType || (documentType == NSPlainTextDocumentType))
    {
        wrapper = [self fileWrapperFromRange:range documentAttributes:attributesDict error:error];
    }
    else
    {
        NSData *data = [self dataFromRange:range documentAttributes:attributesDict error:error];
        if (data) {
            wrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
            if (!wrapper && error) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
        }
    }
	
    return wrapper;
}


@end
