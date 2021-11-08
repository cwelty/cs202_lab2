#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[]){

	int input = 0; 
	if (argc >= 2) input = atoi(argv[1]);
	info(input);
	info(1);
	info(input);
	info(2);
	info(3);
	exit(0);
}
