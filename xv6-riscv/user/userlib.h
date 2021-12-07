#ifndef USERLIB_H
#define USERLIB_H

#include "kernel/types.h"
//#include "stat.h"
//#include "fcntl.h"
#include "../user/user.h"
#include "kernel/spinlock.h"
//struct lock_t lock;

int xchg(int new, int *p);

void thread_create(void *(*start_routine)(void*), void *arg);

void lock_init(struct lock_t *locker);

void lock_acquire(struct lock_t *locker);

void lock_release(struct lock_t *locker);

#endif