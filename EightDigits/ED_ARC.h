//
//  ED_ARC.h
//  EightDigitsTest-NoARC
//
//  Created by Seyithan on 18/09/12.
//  Copyright (c) 2012 Verisun Bilişim Danışmanlık. All rights reserved.
//

#ifndef EightDigits_ED_ARC_h
#define EightDigits_ED_ARC_h

#if !defined(__clang__) || __clang_major__ < 3
#ifndef __bridge
#define __bridge
#endif

#ifndef __bridge_retain
#define __bridge_retain
#endif

#ifndef __bridge_retained
#define __bridge_retained
#endif

#ifndef __autoreleasing
#define __autoreleasing
#endif

#ifndef __strong
#define __strong
#endif

#ifndef __unsafe_unretained
#define __unsafe_unretained
#endif

#ifndef __weak
#define __weak
#endif
#endif

#if __has_feature(objc_arc)
#define ED_ARC_PROP_RETAIN strong
#define ED_ARC_RETAIN(x) (x)
#define ED_ARC_RELEASE(x)
#define ED_ARC_AUTORELEASE(x) (x)
#define ED_ARC_BLOCK_COPY(x) (x)
#define ED_ARC_BLOCK_RELEASE(x)
#define ED_ARC_SUPER_DEALLOC()
#define ED_ARC_AUTORELEASE_POOL_START() @autoreleasepool {
#define ED_ARC_AUTORELEASE_POOL_END() }
#else
#define ED_ARC_PROP_RETAIN retain
#define ED_ARC_RETAIN(x) ([(x) retain])
#define ED_ARC_RELEASE(x) ([(x) release])
#define ED_ARC_AUTORELEASE(x) ([(x) autorelease])
#define ED_ARC_BLOCK_COPY(x) (Block_copy(x))
#define ED_ARC_BLOCK_RELEASE(x) (Block_release(x))
#define ED_ARC_SUPER_DEALLOC() ([super dealloc])
#define ED_ARC_AUTORELEASE_POOL_START() NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
#define ED_ARC_AUTORELEASE_POOL_END() [pool release];
#endif

#endif
