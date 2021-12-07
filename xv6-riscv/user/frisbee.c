#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"

#define NUMTHREADS 20

struct lock_t lock;
int thrower;

void * player(void *arg_ptr);

int main(int argc, char *argv[]){

	int i;
	
	lock_init(&lock);
	
	for(i = 0; i < NUMTHREADS; i++){
		thread_create(player, (void*)&i);
		sleep(10);
	}
	while(wait(0)>=0);
	exit(0);
}

void * player(void *arg_ptr) {
	
	int i, self;
	int *num = (int*) arg_ptr;
	self = *num;
	
	for (i = 0; i < 10; i++){
		if (thrower != self){
			lock_acquire(&lock);
			printf("%d caught frisbee from %d\n", self, thrower);
			thrower = self;
			printf("%d throwing frisbee\n", self);
			sleep(20);
			lock_release(&lock);
		}
		sleep(20);
	}
	exit(0);
}