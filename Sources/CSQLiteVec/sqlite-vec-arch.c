#if defined(SQLITE_VEC_ENABLE_NEON) && \
    !(defined(__ARM_NEON) || defined(__aarch64__))
#undef SQLITE_VEC_ENABLE_NEON
#endif

#if defined(SQLITE_VEC_ENABLE_AVX) && \
    !(defined(__i386__) || defined(__x86_64__))
#undef SQLITE_VEC_ENABLE_AVX
#endif

#include "sqlite-vec.c"
