#ifndef __DRAGON_HEADER__
#define __DRAGON_HEADER__

#include <stdio.h>

/* Flags for dragon_map */
#define D_F_READ        (1U << 1)
#define D_F_WRITE       (1U << 2)
#define D_F_CREATE      (1U << 3)
#define D_F_DONTTRASH   (1U << 4)
#define D_F_VOLATILE    (1U << 5)
#define D_F_USEHOSTBUF  (1U << 6)
#define D_F_DIRECT      (1U << 7)

/* Errors */
typedef enum {
    D_OK        = 0,
    D_ERR_FILE,
    D_ERR_IOCTL,
    D_ERR_UVM,
    D_ERR_INTVAL,
    D_ERR_MEM,
    D_ERR_NOT_IMPLEMENTED
} dragonError_t;

#ifdef __cplusplus
extern "C"
{
#endif
    dragonError_t dragon_map(const char *filename, size_t size, unsigned int flags, void **addr);
    dragonError_t dragon_remap(void *addr, unsigned int flags);
    dragonError_t dragon_trash_set_num_blocks(unsigned long nrblocks);
    dragonError_t dragon_trash_set_num_reserved_sys_cache_pages(unsigned long nrpages);
    dragonError_t dragon_flush(void *addr);
    dragonError_t dragon_unmap(void *addr);
#ifdef __cplusplus
}
#endif

#endif

