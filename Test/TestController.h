//
//  TestController.h
//  JAMultiTypeSavePanelControllerTest
//
//  Created by Jens Ayton on 2009-08-05.
//  Copyright 2009 Jens Ayton. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TestController: NSObject
{
	IBOutlet NSWindow *window;
	IBOutlet NSTextView *textView;
}

- (IBAction) save:(id)sender;

@end
