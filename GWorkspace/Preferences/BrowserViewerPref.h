/* BrowserViewerPref.h
 *  
 * Copyright (C) 2003 Free Software Foundation, Inc.
 *
 * Author: Enrico Sersale <enrico@imago.ro>
 * Date: August 2001
 *
 * This file is part of the GNUstep GWorkspace application
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


#ifndef BROWSERVIEWERPREF_H
#define BROWSERVIEWERPREF_H

#include <AppKit/NSView.h>

#include <Foundation/Foundation.h>
#include "PrefProtocol.h"

@class NSEvent;

@interface Resizer : NSView
{
  NSImage *arrow;
  id prefview;
  id controller;  
}

- (id)initForController:(id)acontroller;

@end

@interface BrowserViewerPref : NSObject <PrefProtocol>
{
  IBOutlet id win;
  IBOutlet id prefbox;

  IBOutlet id controlsbox;
  IBOutlet id colExample;
  IBOutlet id resizerBox;

  IBOutlet id setButt;

  Resizer *resizer;
  int columnsWidth;
}

- (void)tile;

- (void)mouseDownOnResizer:(NSEvent *)theEvent;

- (void)setNewWidth:(int)w;

- (IBAction)setDefaultWidth:(id)sender;

@end

#endif // BROWSERVIEWERPREF_H