/* RtfViewer.m
 *  
 * Copyright (C) 2004 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: January 2004
 *
 * This file is part of the GNUstep Inspector application
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include <AppKit/AppKit.h>
#include "RtfViewer.h"
#include "GNUstep.h"

#define MAXDATA 1000

@implementation RtfViewer

- (void)dealloc
{
  RELEASE (extsarr);
  RELEASE (scrollView);
  RELEASE (errLabel);
  TEST_RELEASE (bundlePath);
  TEST_RELEASE (dataRep);
  TEST_RELEASE (editPath);	
  [super dealloc];
}

- (id)initWithFrame:(NSRect)frameRect
          inspector:(id)insp
{
  self = [super initWithFrame: frameRect];
  
  if (self) {
    NSRect r = [self frame];
    
    extsarr = [[NSArray alloc] initWithObjects: @"rtf", @"rtfd", @"txt", @"text", 
                                                @"c", @"cc", @"C", @"cpp", @"m", 
                                                @"h", @"java", @"class", @"in", 
                                                @"log", @"ac", @"diff", 
                                                @"postamble", @"preamble", nil];
    
    r.origin.y += 45;
    r.size.height -= 45;
    scrollView = [[NSScrollView alloc] initWithFrame: r];
    [scrollView setBorderType: NSBezelBorder];
    [scrollView setHasHorizontalScroller: NO];
    [scrollView setHasVerticalScroller: YES]; 
    [scrollView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
    [[scrollView contentView] setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
    [[scrollView contentView] setAutoresizesSubviews: YES];
    [self addSubview: scrollView]; 

    r = [[scrollView contentView] frame];
    textView = [[NSTextView alloc] initWithFrame: r];
    [textView setBackgroundColor: [NSColor whiteColor]];
    [textView setRichText: YES];
    [textView setEditable: NO];
    [textView setSelectable: NO];
    [textView setHorizontallyResizable: NO];
    [textView setVerticallyResizable: YES];
    [textView setMinSize: NSMakeSize (0, 0)];
    [textView setMaxSize: NSMakeSize (1E7, 1E7)];
    [textView setAutoresizingMask: NSViewHeightSizable | NSViewWidthSizable];
    [[textView textContainer] setContainerSize: NSMakeSize(r.size.width, 1e7)];
    [[textView textContainer] setWidthTracksTextView: YES];
    [textView setUsesRuler: NO];
    [scrollView setDocumentView: textView];
    RELEASE (textView);
    
    r.origin.x = 2;
    r.origin.y = 170;
    r.size.width = [self frame].size.width - 4;
    r.size.height = 25;
    errLabel = [[NSTextField alloc] initWithFrame: r];	
    [errLabel setFont: [NSFont systemFontOfSize: 18]];
    [errLabel setAlignment: NSCenterTextAlignment];
    [errLabel setBackgroundColor: [NSColor windowBackgroundColor]];
    [errLabel setTextColor: [NSColor darkGrayColor]];	
    [errLabel setBezeled: NO];
    [errLabel setEditable: NO];
    [errLabel setSelectable: NO];
    [errLabel setStringValue: NSLocalizedString(@"Invalid Contents", @"")];

    r.origin.x = 141;
    r.origin.y = 10;
    r.size.width = 115;
    r.size.height = 25;
	  editButt = [[NSButton alloc] initWithFrame: r];
	  [editButt setButtonType: NSMomentaryLight];
    [editButt setImage: [NSImage imageNamed: @"common_ret.tiff"]];
    [editButt setImagePosition: NSImageRight];
	  [editButt setTitle: NSLocalizedString(@"Edit", @"")];
	  [editButt setTarget: self];
	  [editButt setAction: @selector(editFile:)];	
    [editButt setEnabled: NO];		
		[self addSubview: editButt]; 
    RELEASE (editButt);

    bundlePath = nil;
    dataRep = nil;
    editPath = nil;

    inspector = insp;
    ws = [NSWorkspace sharedWorkspace];
				
		valid = YES;
  }
	
	return self;
}

- (void)setBundlePath:(NSString *)path
{
  ASSIGN (bundlePath, path);
}

- (NSString *)bundlePath
{
  return bundlePath;
}

- (void)setDataRepresentation:(NSData *)rep
{
  ASSIGN (dataRep, rep);
}

- (NSData *)dataRepresentation
{
  return dataRep;
}

- (void)setIsRemovable:(BOOL)value
{
  removable = value;
}

- (BOOL)isRemovable
{
  return removable;
}

- (void)setIsExternal:(BOOL)value
{
  external = value;
}

- (BOOL)isExternal
{
  return external;
}

- (void)displayPath:(NSString *)path
{
  NSString *ext = [path pathExtension];
  NSData *data = nil;
  NSString *s = nil;
  NSAttributedString *attrstr = nil;
  NSFont *font = nil;  

  if ([self superview]) {      
    [inspector contentsReadyAt: path];
  }
  
  if (([[ext lowercaseString] isEqual: @"rtf"] == NO)
                  && ([[ext lowercaseString] isEqual: @"rtfd"] == NO)) {
    NSDictionary *dict = [[NSFileManager defaultManager] 
                              fileAttributesAtPath: path traverseLink: YES];
    int nbytes = [[dict objectForKey: NSFileSize] intValue];
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath: path];
    int maxbytes = 0;
    
    data = [NSMutableData new];
  
    do {
      maxbytes += MAXDATA;

      [(NSMutableData *)data appendData: 
          [handle readDataOfLength: ((nbytes >= MAXDATA) ? MAXDATA : nbytes)]];

      s = [[NSString alloc] initWithData: data
                                encoding: [NSString defaultCStringEncoding]];
    } while ((s == nil) && (maxbytes < nbytes));

    [handle closeFile];
    RELEASE (data);

    attrstr = [[NSAttributedString alloc] initWithString: s];
    RELEASE (s);
    AUTORELEASE (attrstr);

    font = [NSFont systemFontOfSize: 8.0];

  } else if ([[ext lowercaseString] isEqual: @"rtf"]) {
    data = [NSData dataWithContentsOfFile: path];

    if (data) {    
      attrstr = [[NSAttributedString alloc] initWithRTF: data
						                         documentAttributes: NULL];
      AUTORELEASE (attrstr);
    }

  } else if ([[ext lowercaseString] isEqual: @"rtfd"]) {
    data = [NSData dataWithContentsOfFile: path];

    if (data) {
      attrstr = [[NSAttributedString alloc] initWithRTFD: data
						                          documentAttributes: NULL];
      AUTORELEASE (attrstr);
    }
  }
  
  if (attrstr) {
    ASSIGN (editPath, path);
  
    if (valid == NO) {
      valid = YES;
      [errLabel removeFromSuperview];
      [self addSubview: scrollView]; 
    }
  
    [[textView textStorage] setAttributedString: attrstr];
    
    if (font) {
		  [[textView textStorage] addAttribute: NSFontAttributeName 
                                     value: font 
                                     range: NSMakeRange(0, [attrstr length])];
    }
    
    [editButt setEnabled: YES];			
    [[self window] makeFirstResponder: editButt];
    
  } else {
    if (valid == YES) {
      valid = NO;
      [scrollView removeFromSuperview];
			[self addSubview: errLabel];
			[editButt setEnabled: NO];			
    }
  }
}

- (void)displayLastPath:(BOOL)forced
{
  if (editPath) {
    if (forced) {
      [self displayPath: editPath];
    } else {
      [inspector contentsReadyAt: editPath];
    }
  }
}

- (void)displayData:(NSData *)data 
             ofType:(NSString *)type
{
}

- (NSString *)currentPath
{
  return editPath;
}

- (void)stopTasks
{
}

- (BOOL)canDisplayPath:(NSString *)path
{
  NSDictionary *attributes;
	NSString *defApp, *fileType, *extension;

  attributes = [[NSFileManager defaultManager] fileAttributesAtPath: path
                                                       traverseLink: YES];
  if ([attributes objectForKey: NSFileType] == NSFileTypeDirectory) {
    return NO;
  }		

	[ws getInfoForFile: path application: &defApp type: &fileType];
	
  if (([fileType isEqual: NSPlainFileType] == NO)
                  && ([fileType isEqual: NSShellCommandFileType] == NO)) {
    return NO;
  }

	extension = [path pathExtension];

  if ([extsarr containsObject: [extension lowercaseString]]) {
    return YES;
  }
  
	return NO;
}

- (BOOL)canDisplayDataOfType:(NSString *)type
{
  return NO;
}

- (NSString *)winname
{
	return NSLocalizedString(@"Rtf-Txt Inspector", @"");	
}

- (NSString *)description
{
	return NSLocalizedString(@"This Inspector allow you view the content of an Rtf ot txt file", @"");	
}

- (void)editFile:(id)sender
{
	NSString *appName;
  NSString *type;

  [ws getInfoForFile: editPath application: &appName type: &type];

	if (appName != nil) {
		[ws openFile: editPath withApplication: appName];
	}
}

@end
