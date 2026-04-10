//
//  OOMBoundary-Bridging-Header.h
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/03/31.
//

#ifndef OOMBoundary_Bridging_Header_h
#define OOMBoundary_Bridging_Header_h

#include <os/proc.h>
#include <sys/types.h>

// Code signing operations
int csops(pid_t pid, unsigned int ops, void *useraddr, size_t usersize);

#endif /* OOMBoundary_Bridging_Header_h */
