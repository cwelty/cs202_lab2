#include "types.h"
#include "stat.h"
#include "fnctl.h"
#include "user.h"
#include "x86.h"
#include "param.h"
#include "syscall.h"
#include "traps.h"
#include "fs.h"

#define PAGESIZE 4096

int lock_init(lock_t *locker){
	locker->flag = 0;
	return 0;
}

/*void lock_acquire(lock_t *locker){
	while(xchg(&locker->flag, 1) != 0) ;
}

void lock_release(lock_t *locker){
	xchg(&locker->flag, 0);
}*/
//ABOVE HAS BEEN COMPROMISED FOR THE TIME BEING 

//shreeyakamath
int thread_create(void (*start_routine)(void*), void *arg){

	lock_t lock;
	lock_init(&lock);
	lock_acquire(&lock);
	void *stack = malloc(PAGESIZE*2);
	lock_release(&lock);
	
	if((uint)stack % PAGESIZE)
		stack = stack + (PAGESIZE - (uint)stack % PAGESIZE);
	
	int result = clone(start_routine,arg,stack);
	return result;
}
