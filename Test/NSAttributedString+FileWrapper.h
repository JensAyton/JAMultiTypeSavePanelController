//
//  NSAttributedString+FileWrapper.h
//  JAMultiTypeSavePanelControllerTest
//
//  Created by Jan on 26.01.12.
//  Copyright (c) 2012 geheimwerk.de. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (FileWrapper)

- (NSFileWrapper *)fileWrapperForDocumentType:(NSString *)documentType error:(NSError **)error;

@end
