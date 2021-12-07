#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "../user/user.h"
#include "../kernel/userlib.h"

int main(int argc, char argv[])
{
    // int arr[] = {atoi(argv[1]), atoi(argv[2])};
    // printf("%d\n", arr[0]); 
    void test = malloc(4096); // FIXME placeholder, need to get pointer for start_routine()?
    // int threads = 0;
    // if (argc >= 2) threads = atoi(argv[1]);
    // void *args = (void &) &threads;
    // printf("Kernel %d\n", n);
    thread_create(test, atoi(argv[1]), atoi(argv[2]));
    exit(0);
}