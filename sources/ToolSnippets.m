//
//  ToolSnippets.m
//  iTerm
//
//  Copy from ToolPasteHistory by Rubin on 10/13/11.
//

#import "ToolSnippets.h"

#import "iTermCompetentTableRowView.h"
#import "iTermController.h"
#import "iTermToolWrapper.h"
#import "NSDateFormatterExtras.h"
#import "NSTableColumn+iTerm.h"
#import "NSTextField+iTerm.h"
#import "PseudoTerminal.h"
#import "NSFileManager+iTerm.h"

static const CGFloat kButtonHeight = 23;
static const CGFloat kMargin = 4;

@implementation ToolSnippets {
    NSScrollView *scrollView_;
    NSTableView *tableView_;
    NSButton *clear_;
    NSArray<NSDictionary *> *snippetsConf_;
    NSTimer *minuteRefreshTimer_;
    NSTimer *getSnippetsTimer_;
    BOOL shutdown_;
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        clear_ = [[NSButton alloc] initWithFrame:NSMakeRect(0, frame.size.height - kButtonHeight, frame.size.width, kButtonHeight)];
        [clear_ setButtonType:NSMomentaryPushInButton];
        [clear_ setTitle:@"Clear All"];
        [clear_ setTarget:self];
        [clear_ setAction:@selector(clear:)];
        [clear_ setBezelStyle:NSSmallSquareBezelStyle];
        [clear_ sizeToFit];
        [clear_ setAutoresizingMask:NSViewMinYMargin];
        [self addSubview:clear_];
        [clear_ release];
        
        scrollView_ = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - kButtonHeight - kMargin)];
        [scrollView_ setHasVerticalScroller:YES];
        [scrollView_ setHasHorizontalScroller:NO];
        [scrollView_ setBorderType:NSBezelBorder];
        NSSize contentSize = [scrollView_ contentSize];
        [scrollView_ setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        if (@available(macOS 10.14, *)) { } else {
            scrollView_.drawsBackground = NO;
        }

        tableView_ = [[NSTableView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
        NSTableColumn *col;
        col = [[[NSTableColumn alloc] initWithIdentifier:@"title"] autorelease];
        [col setEditable:NO];
        [tableView_ addTableColumn:col];
        [[col headerCell] setStringValue:@"Title"];
        
        col = [[[NSTableColumn alloc] initWithIdentifier:@"content"] autorelease];
        [col setEditable:NO];
        [tableView_ addTableColumn:col];
        [[col headerCell] setStringValue:@"Content"];
        
        [tableView_ setDataSource:self];
        [tableView_ setDelegate:self];
        tableView_.intercellSpacing = NSMakeSize(tableView_.intercellSpacing.width, 0);
        tableView_.rowHeight = 15;
        
        [tableView_ setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

        [tableView_ setDoubleAction:@selector(doubleClickOnTableView:)];
        [tableView_ setAutoresizingMask:NSViewWidthSizable];
        
        [scrollView_ setDocumentView:tableView_];
        [self addSubview:scrollView_];
        
        [tableView_ sizeToFit];
        [tableView_ setColumnAutoresizingStyle:NSTableViewSequentialColumnAutoresizingStyle];
        
        [tableView_ reloadData];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(getSnippets:)
                                                     name:NSWindowDidBecomeKeyNotification
                                                   object:nil];
        
        // Updating the table data causes the cursor to change into an arrow!
        [self performSelector:@selector(fixCursor) withObject:nil afterDelay:0];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [minuteRefreshTimer_ invalidate];
    [tableView_ release];
    [scrollView_ release];
    [super dealloc];
}

- (void)shutdown {
    shutdown_ = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [minuteRefreshTimer_ invalidate];
    minuteRefreshTimer_ = nil;
    [getSnippetsTimer_ invalidate];
    getSnippetsTimer_ = nil;
}

- (NSSize)contentSize {
    NSSize size = [scrollView_ contentSize];
    size.height = [[tableView_ headerView] frame].size.height;
    size.height += [tableView_ numberOfRows] * ([tableView_ rowHeight] + [tableView_ intercellSpacing].height);
    return size;
}

- (void)relayout {
    NSRect frame = self.frame;
    [clear_ setFrame:NSMakeRect(0, frame.size.height - kButtonHeight, frame.size.width, kButtonHeight)];
    [scrollView_ setFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height - kButtonHeight - kMargin)];
    NSSize contentSize = [self contentSize];
    [tableView_ setFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
}

- (BOOL)isFlipped {
    return YES;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[[iTermCompetentTableRowView alloc] initWithFrame:NSZeroRect] autorelease];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [snippetsConf_ count];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    static NSString *const identifier = @"ToolSnippetsEntry";
    NSTextField *result = [tableView makeViewWithIdentifier:identifier owner:self];
    if (result == nil) {
        result = [NSTextField it_textFieldForTableViewWithIdentifier:identifier];
    }
    NSString *value = [self stringForTableColumn:tableColumn row:row];
    if (value == nil) {
        value = @"";
    }
    result.stringValue = value;
    
    return result;
}

- (NSString *)stringForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if (rowIndex >= [snippetsConf_ count]) {
        return @"";
    }
    NSDictionary *dic = snippetsConf_[rowIndex];
    if (dic == nil) {
        return @"";
    }
    
    return [dic objectForKey:aTableColumn.identifier];
}

- (void)pasteboardHistoryDidChange:(id)sender {
    [self update];
}

- (void)update {
    // Updating the table data causes the cursor to change into an arrow!
    [self performSelector:@selector(fixCursor) withObject:nil afterDelay:0];
    
    NSResponder *firstResponder = [[tableView_ window] firstResponder];
    if (firstResponder != tableView_) {
        [tableView_ scrollToEndOfDocument:nil];
    }
}

- (void)fixCursor {
    if (shutdown_) {
        return;
    }
    iTermToolWrapper *wrapper = self.toolWrapper;
    [wrapper.delegate.delegate toolbeltUpdateMouseCursor];
}

- (void)doubleClickOnTableView:(id)sender {
    NSInteger selectedIndex = [tableView_ selectedRow];
    if (selectedIndex < 0) {
        return;
    }

    NSString * value = [snippetsConf_[selectedIndex] objectForKey:@"content"];
    value = [value stringByAppendingString:@"\n"];
    PTYTextView *textView = [[iTermController sharedInstance] frontTextView];
    [textView sendText:value withEvent:nil];
    [textView.window makeFirstResponder:textView];
}

- (void)clear:(id)sender {
    [tableView_ reloadData];
    // Updating the table data causes the cursor to change into an arrow!
    [self performSelector:@selector(fixCursor) withObject:nil afterDelay:0];
}

- (CGFloat)minimumHeight {
    return 60;
}

- (NSArray*)getSnippets {
    NSError *error;
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *appsupport = [fileManager applicationSupportDirectory];
    NSString *path = [appsupport stringByAppendingPathComponent:@"Toolbelt"];
    success = [fileManager fileExistsAtPath:path];
    if (!success) {
        success = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
        if (!success) {
            NSLog(@"snippets folder creation failed.");
            return nil;
        }
    }
    
    path = [path stringByAppendingPathComponent:@"Snippets.json"];
    NSData *data= [fileManager contentsAtPath:path];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    return array;
}

- (void)getSnippets:(id)sender {
    if (shutdown_) {
        return;
    }

    snippetsConf_ = [[self getSnippets] retain];
    [tableView_ reloadData];
}

@end
