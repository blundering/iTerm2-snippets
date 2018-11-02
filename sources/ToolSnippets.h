//
//  ToolSnippets.h
//  iTerm
//
//  Copy from ToolPasteHistory by Rubin on 10/13/11.
//

#import <Cocoa/Cocoa.h>

#import "FutureMethods.h"
#import "iTermToolbeltView.h"
#import "PasteboardHistory.h"

@interface ToolSnippets : NSView <ToolbeltTool, NSTableViewDataSource, NSTableViewDelegate>

@end
