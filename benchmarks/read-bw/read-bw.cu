#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>

#include <cuda.h>
#include <cuda_runtime.h>

#include <dragon.h>

#define CUDA_CALL_SAFE(f) \
    do \
    {                                                        \
        cudaError_t _cuda_error = f;                         \
        if (_cuda_error != cudaSuccess)                      \
        {                                                    \
            fprintf(stderr,  \
                "%s, %d, CUDA ERROR: %s %s\n",  \
                __FILE__,   \
                __LINE__,   \
                cudaGetErrorName(_cuda_error),  \
                cudaGetErrorString(_cuda_error) \
            ); \
            abort(); \
            return EXIT_FAILURE; \
        } \
    } while (0)        

double time_diff(struct timeval tv_start, struct timeval tv_stop)
{
    return (double)(tv_stop.tv_sec - tv_start.tv_sec) * 1000.0 + (double)(tv_stop.tv_usec - tv_start.tv_usec) / 1000.0;
}

#define NUM_THREADS_PER_BLOCK 1024
#define GPU_PAGE_SIZE (1LLU << 21)

/** 
 * Each block reads 2MB (1 GPU page). As we have 1024 threads per block, each thread reads 2KB.
 */

__global__ void kernel(volatile uint32_t *g_buf) 
{
    int block_id = blockIdx.x;

    // Calculate the start address of this block
    volatile uint32_t *buf = (volatile uint32_t *)(((char *)g_buf) + block_id * GPU_PAGE_SIZE);

    int tid = threadIdx.x;

    int num_elements = GPU_PAGE_SIZE / NUM_THREADS_PER_BLOCK / sizeof(uint32_t);

    uint64_t start, stop;
    uint32_t tmp;

    asm volatile ("mov.u64 %0, %%globaltimer;" : "=l"(start));
    for (int i = 0; i < num_elements; ++i)
        tmp = buf[i * NUM_THREADS_PER_BLOCK + tid];
    asm volatile ("mov.u64 %0, %%globaltimer;" : "=l"(stop));
}

int main(int argc, char *argv[])
{
    volatile uint32_t *g_buf;
    size_t num_tblocks;          
    int size_order;
    size_t total_size;


    float kernel_time = 0;        // in ms
    double free_time = 0;         // in ms
    double map_time = 0;          // in ms
    double bw = 0;                // in MB/s

    cudaEvent_t start_event, stop_event;
    struct timeval tv_start, tv_stop;

    int use_direct = 0;
    unsigned int flags = D_F_READ;

    if (argc != 4)
    {
        fprintf(stderr, "Usage: %s <file> <size_in_GiB> <0: page-cache, 1: direct>\n", argv[0]);
        return EXIT_SUCCESS;
    }

    size_order = atoi(argv[2]);

    use_direct = atoi(argv[3]);
    if (use_direct)
    {
        flags |= D_F_DIRECT;
        printf("Use D_F_DIRECT\n");
    }
    else
    {
        printf("NOT USING D_F_DIRECT\n");
    }
    
    total_size = ((size_t)1 << 30) * size_order;

    // Each block reads exactly 1 GPU page (2MB).
    num_tblocks = total_size / GPU_PAGE_SIZE;

    CUDA_CALL_SAFE(cudaEventCreate(&start_event));
    CUDA_CALL_SAFE(cudaEventCreate(&stop_event));

    gettimeofday(&tv_start, NULL);
    if (dragon_map(argv[1], total_size, flags, (void **)&g_buf) != D_OK)
        return EXIT_FAILURE;
    fprintf(stderr, "g_buf: %p\n", g_buf);
    gettimeofday(&tv_stop, NULL);

    map_time = time_diff(tv_start, tv_stop);

    CUDA_CALL_SAFE(cudaEventRecord(start_event));
    kernel<<< num_tblocks, NUM_THREADS_PER_BLOCK >>>(g_buf);
    CUDA_CALL_SAFE(cudaEventRecord(stop_event));

    CUDA_CALL_SAFE(cudaEventSynchronize(stop_event));
    CUDA_CALL_SAFE(cudaEventElapsedTime(&kernel_time, start_event, stop_event));

    CUDA_CALL_SAFE(cudaDeviceSynchronize());

    gettimeofday(&tv_start, NULL);
    if (dragon_unmap((void *)g_buf) != D_OK)
        return EXIT_FAILURE;
    gettimeofday(&tv_stop, NULL);

    free_time = time_diff(tv_start, tv_stop);

    bw = ((double)total_size / (double)1024) / (double)kernel_time;

    printf("==> header: total_size (GB),kernel_time (ms),free_time (ms),map_time (ms),bw (MB/s)\n");
    printf("==> data: %d,%f,%f,%f,%f\n", size_order, kernel_time, free_time, map_time, bw);

    return EXIT_SUCCESS;
}

