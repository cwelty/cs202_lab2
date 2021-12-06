#include "types.h"
#include stat.h
#include "fcntl.h"
#include "user.h"
#include "spinlock.h"

struct lock_t lock;

void thread_create(void *(*start_routine)(void*), void *arg){
	
	void *nSp = malloc(4096);
	int rc;
	rc = clone(nSp, 4096);
	
	if (rc == 0){
		(*start_routine)(arg);
		exit();
	}
}

void lock_init(struct lock_t *locker){
	locker->locked = 0;
}

void lock_acquire(struct lock_t *locker){
	while(xchg(&locker->locked, 1) != 0);	
}

void lock_release(struct lock_t *locker){
	xchg(&locker->locked, 0);
}

int xchg(int new, int *p){
	int old = p;
	*p = new;
	return old;
}

