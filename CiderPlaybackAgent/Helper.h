//
//  Helper.h
//  CiderPlaybackAgent
//
//  Created by Sherlock LUK on 06/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

#ifndef Helper_h
#define Helper_h

#include <stdio.h>
#include <Foundation/Foundation.h>
#include <sys/event.h>

void noteProcDeath(
    CFFileDescriptorRef fdref,
    CFOptionFlags callBackTypes,
                   void* info);

void suicide_if_we_become_a_zombie(int parent_pid);

#endif /* Helper_h */
