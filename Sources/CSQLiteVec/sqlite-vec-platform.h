#ifndef SQLITE_VEC_DATA_PLATFORM_H
#define SQLITE_VEC_DATA_PLATFORM_H

#if defined(SQLITE_VEC_ENABLE_NEON) &&                                         \
    !(defined(__ARM_NEON) || defined(__aarch64__))
#undef SQLITE_VEC_ENABLE_NEON
#endif

#if defined(SQLITE_VEC_ENABLE_AVX) &&                                          \
    !(defined(__i386__) || defined(__x86_64__))
#undef SQLITE_VEC_ENABLE_AVX
#endif

#ifdef SQLITE_VEC_ENABLE_AVX
// The compiler runtime caches CPU features and checks the OS's AVX
// register-state support.
static int sqlite_vec_cpu_supports_avx(void) {
  return __builtin_cpu_supports("avx") != 0;
}
#endif

#endif
