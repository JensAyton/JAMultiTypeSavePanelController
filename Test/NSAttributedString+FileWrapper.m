/*	
	NSAttributedString+FileWrapper.m
	
	Category on NSAttributedString for simplifying NSFileWrapper creation.
	
	
	© 2012 Jan Weiß
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "NSAttributedString+FileWrapper.h"

@implementation NSAttributedString (FileWrapper)

- (NSFileWrapper *)fileWrapperForDocumentType:(NSString *)documentType 
										error:(NSError **)error;
{
	return [self fileWrapperForDocumentType:documentType attributes:nil error:error];
}

- (NSFileWrapper *)fileWrapperForDocumentType:(NSString *)documentType 
								   attributes:(NSDictionary *)attributes 
										error:(NSError **)error;
{
    NSFileWrapper *wrapper = nil;
    NSRange range = {0, self.length};
    NSDictionary *attributesDict;
	
	if (attributes == nil) 
	{
		attributesDict = [NSDictionary dictionaryWithObject:documentType forKey:NSDocumentTypeDocumentAttribute];
	} else 
	{
		NSMutableDictionary *mutableAttributesDict = [[attributes mutableCopy] autorelease];
		[mutableAttributesDict setObject:documentType forKey:NSDocumentTypeDocumentAttribute];
		attributesDict = mutableAttributesDict;
	}
    
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
