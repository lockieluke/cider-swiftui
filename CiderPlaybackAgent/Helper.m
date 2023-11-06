//
//  Helper.m
//  CiderPlaybackAgent
//
//  Created by Sherlock LUK on 06/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

#include "Helper.h"

void noteProcDeath(
    CFFileDescriptorRef fdref,
    CFOptionFlags callBackTypes,
    void* info)
{
    // LOG_DEBUG(@"noteProcDeath... ");

    struct kevent kev;
    int fd = CFFileDescriptorGetNativeDescriptor(fdref);
    kevent(fd, NULL, 0, &kev, 1, NULL);
    // take action on death of process here
    unsigned int dead_pid = (unsigned int)kev.ident;

    CFFileDescriptorInvalidate(fdref);
    CFRelease(fdref); // the CFFileDescriptorRef is no longer of any use in this example

    int our_pid = getpid();
    // when our parent dies we die as well..
    NSLog(@"exit! parent process (pid %u) died. no need for us (pid %i) to stick around", dead_pid, our_pid);
    exit(EXIT_SUCCESS);
}


void suicide_if_we_become_a_zombie(int parent_pid) {
    // int parent_pid = getppid();
    // int our_pid = getpid();
    // LOG_ERROR(@"suicide_if_we_become_a_zombie(). parent process (pid %u) that we monitor. our pid %i", parent_pid, our_pid);

    int fd = kqueue();
    struct kevent kev;
    EV_SET(&kev, parent_pid, EVFILT_PROC, EV_ADD|EV_ENABLE, NOTE_EXIT, 0, NULL);
    kevent(fd, &kev, 1, NULL, 0, NULL);
    CFFileDescriptorRef fdref = CFFileDescriptorCreate(kCFAllocatorDefault, fd, true, noteProcDeath, NULL);
    CFFileDescriptorEnableCallBacks(fdref, kCFFileDescriptorReadCallBack);
    CFRunLoopSourceRef source = CFFileDescriptorCreateRunLoopSource(kCFAllocatorDefault, fdref, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), source, kCFRunLoopDefaultMode);
    CFRelease(source);
}
