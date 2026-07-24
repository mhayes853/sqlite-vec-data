#if defined(SQLITE_VEC_ENABLE_NEON) && \
    !(defined(__ARM_NEON) || defined(__aarch64__))
#undef SQLITE_VEC_ENABLE_NEON
#endif

#include "sqlite-vec.c"
