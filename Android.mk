# Android (AODP and NDK) makefile for jpeg-turbo library

LOCAL_PATH:= $(call my-dir)

# If true, also build as a shared library
JPEGTURBO_SHARED=false

# Version of JPEG API to compile
JPEGTURBO_CFLAGS := -DJPEG_LIB_VERSION=62

# Those options are available only with API >= 70
JPEGTURBO_WITH_ARITH:=false
JPEGTURBO_WITH_ARITH_ENC:=false
JPEGTURBO_WITH_ARITH_DEC:=false

# ashmem support not exposed as NDK API
JPEGTURBO_WITH_ASHMEM:=0
ifeq ($(NDK_ROOT),)
ifneq ($(BUILD_HOST),true)
JPEGTURBO_WITH_ASHMEM:=true
endif
endif

# List of source files
JPEGTURBO_SRC_FILES := jcapimin.c jcapistd.c jccoefct.c jccolor.c
JPEGTURBO_SRC_FILES += jcdctmgr.c jchuff.c jcinit.c jcmainct.c jcmarker.c
JPEGTURBO_SRC_FILES += jcmaster.c jcomapi.c jcparam.c jcphuff.c jcprepct.c
JPEGTURBO_SRC_FILES += jcsample.c jctrans.c jdapimin.c jdapistd.c jdatadst.c
JPEGTURBO_SRC_FILES += jdatasrc.c jdcoefct.c jdcolor.c jddctmgr.c jdhuff.c
JPEGTURBO_SRC_FILES += jdinput.c jdmainct.c jdmarker.c jdmaster.c jdmerge.c
JPEGTURBO_SRC_FILES += jdphuff.c jdpostct.c jdsample.c jdtrans.c jerror.c
JPEGTURBO_SRC_FILES += jfdctflt.c jfdctfst.c jfdctint.c jidctflt.c jidctfst.c
JPEGTURBO_SRC_FILES += jidctint.c jidctred.c jquant1.c jquant2.c jutils.c
JPEGTURBO_SRC_FILES += jmemmgr.c

ifeq ($(JPEGTURBO_WITH_ARITH),true)
JPEGTURBO_SRC_FILES += jaricom.c
endif
ifeq ($(JPEGTURBO_WITH_ARITH_ENC),true)
JPEGTURBO_SRC_FILES += jcarith.c
endif
ifeq ($(JPEGTURBO_WITH_ARITH_DEC),true)
JPEGTURBO_SRC_FILES += jdarith.c
endif

JPEGTURBO_SRC_FILES += \
	turbojpeg.c \
	transupp.c \
	jdatadst-tj.c jdatasrc-tj.c

ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
# Enable support for NEON optimization. Note that cpu features will be
# detected at runtime, and NEON instruction will be executed if and only
# if cpu has NEON feature
JPEGTURBO_CFLAGS += -D__ARM_NEON__

JPEGTURBO_SRC_FILES += \
	simd/jsimd_arm_neon.S \
	simd/jsimd_arm.c
else
# On armv6, fallback to pure C implementation
JPEGTURBO_SRC_FILES += jsimd_none.c
endif

ifeq ($(JPEG_WITH_ASHMEM),true)
# Use ashmem as backing store in decoder
JPEGTURBO_CFLAGS += -DUSE_ANDROID_ASHMEM
JPEGTURBO_SRC_FILES += \
	jmem-ashmem.c
else
# Use standard (libc) memory allocator
JPEGTURBO_SRC_FILES += \
	jmemnobs.c
endif

# the original android memory manager.
# use sdcard as libjpeg decoder's backing store
#JPEGTURBO_SRC_FILES += \
#	jmem-android.c

JPEGTURBO_CFLAGS += -DAVOID_TABLES
ifeq ($(DEBUG_BUILD),true)
# Debug build, turn off all optimization
JPEGTURBO_CFLAGS += -DDEBUG -UNDEBUG -O0 -g
else
# Performance for this specific library requires pushing further
# optimization level, and favor performance over code size
JPEGTURBO_CFLAGS += -O3
JPEGTURBO_CFLAGS += -fstrict-aliasing -fprefetch-loop-arrays
endif

# Enable tile based decode
JPEGTURBO_CFLAGS += -DANDROID_TILE_BASED_DECODE

# Static library
include $(CLEAR_VARS)

LOCAL_MODULE:= libyahoo_jpegturbo
LOCAL_MODULE_TAGS := optional

LOCAL_SRC_FILES := $(JPEGTURBO_SRC_FILES)
LOCAL_CFLAGS := $(JPEGTURBO_CFLAGS)
LOCAL_ARM_MODE := arm
LOCAL_PRELINK_MODULE := false

# If uncommented, export all headers in this directory to be available
# from other module relying on this package, without having to add this
# directory into their header search path
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH) 

# If static library has to be linked inside a larger shared library later,
# all code has to be compiled as PIC (Position Independant Code)
LOCAL_CFLAGS += -fPIC -DPIC

ifneq ($(NDK_ROOT),)
# AOSP toolchain supports gold linker
LOCAL_LDLIBS += -fuse-ld=gold 
endif
include $(BUILD_STATIC_LIBRARY)

ifeq ($(JPEGTURBO_SHARED),true)
# Shared library
include $(CLEAR_VARS)

LOCAL_MODULE:= libyahoo_jpegturbo
LOCAL_MODULE_TAGS := optional

LOCAL_SRC_FILES := $(JPEGTURBO_SRC_FILES)
LOCAL_CFLAGS := $(JPEGTURBO_CFLAGS)
LOCAL_ARM_MODE := arm
LOCAL_PRELINK_MODULE := false

ifeq ($(JPEGTURBO_WITH_ASHMEM),true)
LOCAL_SHARED_LIBRARIES += libcutils
endif

ifneq ($(NDK_ROOT),)
LOCAL_LDLIBS += -fuse-ld=gold 
endif
include $(BUILD_SHARED_LIBRARY)
endif
