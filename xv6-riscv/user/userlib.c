#include "userlib.h"
#include "user/user.h"
//#include "kernel/riscv.h"
//struct lock_t lock;

#define PGSIZE 4096

int xchg(int new, int *p){
	int* old = p;
	*p = new;
	return *old;
}

void thread_create(void *(*start_routine)(void*), void *arg){
	
	void *nSp = malloc(PGSIZE);
	//uint64 ptr = (uint64) (nSp);
	int rc;
	rc = clone(nSp, PGSIZE);
	printf("pre-rc check\n");
	if (rc == 0){
		printf("Starting the routine...\n");
		(*start_routine)(arg);
		exit(0);
	}
}

void lock_init(struct lock_t *locker){
	locker->locked = 0;
}

void lock_acquire(struct lock_t *locker){
	int i = 1;
	int *p = &i;
	while(xchg(locker->locked, p) != 0);	
}

void lock_release(struct lock_t *locker){
	xchg(locker->locked, 0);
}

