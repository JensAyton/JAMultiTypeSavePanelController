//
//  NSAttributedString+FileWrapper.h
//  JAMultiTypeSavePanelControllerTest
//
//  Created by Jan on 26.01.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAttributedString (FileWrapper)

- (NSFileWrapper *)fileWrapperForDocumentType:(NSString *)documentType 
										error:(NSError **)error;

- (NSFileWrapper *)fileWrapperForDocumentType:(NSString *)documentType 
								   attributes:(NSDictionary *)attributes 
										error:(NSError **)error;

@end
