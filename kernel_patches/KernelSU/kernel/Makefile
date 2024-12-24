kernelsu-objs := ksu.o
kernelsu-objs += allowlist.o
kernelsu-objs += apk_sign.o
kernelsu-objs += sucompat.o
kernelsu-objs += throne_tracker.o
kernelsu-objs += core_hook.o
kernelsu-objs += ksud.o
kernelsu-objs += embed_ksud.o
kernelsu-objs += kernel_compat.o

kernelsu-objs += selinux/selinux.o
kernelsu-objs += selinux/sepolicy.o
kernelsu-objs += selinux/rules.o
ccflags-y += -I$(srctree)/security/selinux -I$(srctree)/security/selinux/include
ccflags-y += -I$(objtree)/security/selinux -include $(srctree)/include/uapi/asm-generic/errno.h

obj-$(CONFIG_KSU) += kernelsu.o

# .git is a text file while the module is imported by 'git submodule add'.
ifeq ($(shell test -e $(srctree)/$(src)/../.git; echo $$?),0)
$(shell cd $(srctree)/$(src); /usr/bin/env PATH="$$PATH":/usr/bin:/usr/local/bin [ -f ../.git/shallow ] && git fetch --unshallow)
KSU_GIT_VERSION := $(shell cd $(srctree)/$(src); /usr/bin/env PATH="$$PATH":/usr/bin:/usr/local/bin git rev-list --count HEAD)
# ksu_version: major * 10000 + git version + 200 for historical reasons
$(eval KSU_VERSION=$(shell expr 10000 + $(KSU_GIT_VERSION) + 200))
$(info -- KernelSU version: $(KSU_VERSION))
ccflags-y += -DKSU_VERSION=$(KSU_VERSION)
else # If there is no .git file, the default version will be passed.
$(warning "KSU_GIT_VERSION not defined! It is better to make KernelSU a git submodule!")
# Else hardcode the latest KSU_VERSION from https://github.com/tiann/KernelSU/tree/main
# And it will be updated over time accordingly
ccflags-y += -DKSU_VERSION=11986
endif

ccflags-y += -Wno-implicit-function-declaration -Wno-strict-prototypes -Wno-int-conversion -Wno-gcc-compat
ccflags-y += -Wno-declaration-after-statement -Wno-unused-function

## Define supported KernelSU variants ##
KSU_EXPECTED_LEGACY_SIZE := 0x033b
KSU_EXPECTED_LEGACY_HASH := c371061b19d8c7d7d6133c6a9bafe198fa944e50c1b31c9d8daa8d7f1fc2d2d6
ccflags-y += -DEXPECTED_LEGACY_SIZE=$(KSU_EXPECTED_LEGACY_SIZE)
ccflags-y += -DEXPECTED_LEGACY_HASH=\"$(KSU_EXPECTED_LEGACY_HASH)\"
$(info -- Currently supported KernelSU variants --)
$(info -- KernelSU with legacy overlayfs => https://github.com/tiann/KernelSU)
$(info -- Legacy KernelSU Manager signature size: $(KSU_EXPECTED_LEGACY_SIZE))
$(info -- Legacy KernelSU Manager signature hash: $(KSU_EXPECTED_LEGACY_HASH))

KSU_EXPECTED_MAGIC_SIZE := 384
KSU_EXPECTED_MAGIC_HASH := 7e0c6d7278a3bb8e364e0fcba95afaf3666cf5ff3c245a3b63c8833bd0445cc4
ccflags-y += -DEXPECTED_MAGIC_SIZE=$(KSU_EXPECTED_MAGIC_SIZE)
ccflags-y += -DEXPECTED_MAGIC_HASH=\"$(KSU_EXPECTED_MAGIC_HASH)\"
$(info )
$(info -- KernelSU with Magic Mount => https://github.com/5ec1cff/KernelSU)
$(info -- Magic Mount KernelSU Manager signature size: $(KSU_EXPECTED_MAGIC_SIZE))
$(info -- Magic Mount KernelSU Manager signature hash: $(KSU_EXPECTED_MAGIC_HASH))

KSU_EXPECTED_NEXT_SIZE := 0x3e6
KSU_EXPECTED_NEXT_HASH := 79e590113c4c4c0c222978e413a5faa801666957b1212a328e46c00c69821bf7
ccflags-y += -DEXPECTED_NEXT_SIZE=$(KSU_EXPECTED_NEXT_SIZE)
ccflags-y += -DEXPECTED_NEXT_HASH=\"$(KSU_EXPECTED_NEXT_HASH)\"
$(info )
$(info -- KernelSU-Next => https://github.com/rifsxd/KernelSU-Next)
$(info -- Next KernelSU Manager signature size: $(KSU_EXPECTED_NEXT_SIZE))
$(info -- Next KernelSU Manager signature hash: $(KSU_EXPECTED_NEXT_HASH))

## For non-gki compatiblity ##
ccflags-y += -DKSU_UMOUNT
ifneq ($(shell grep -Eq "^static int can_umount" $(srctree)/fs/namespace.c; echo $$?),0)
$(info -- KSU_SUSFS: adding function 'static int can_umount(const struct path *path, int flags);' to $(srctree)/fs/namespace.c)
CAN_UMOUNT = static int can_umount(const struct path *path, int flags)\n\
{\n\t\
        struct mount *mnt = real_mount(path->mnt);\n\t\
        if (flags & ~(MNT_FORCE | MNT_DETACH | MNT_EXPIRE | UMOUNT_NOFOLLOW))\n\t\t\
                return -EINVAL;\n\t\
        if (!may_mount())\n\t\t\
                return -EPERM;\n\t\
        if (path->dentry != path->mnt->mnt_root)\n\t\t\
                return -EINVAL;\n\t\
        if (!check_mnt(mnt))\n\t\t\
                return -EINVAL;\n\t\
        if (mnt->mnt.mnt_flags & MNT_LOCKED)\n\t\t\
                return -EINVAL;\n\t\
        if (flags & MNT_FORCE && !capable(CAP_SYS_ADMIN))\n\t\t\
                return -EPERM;\n\t\
        return 0;\n\
}\n
$(shell sed -i '/^static bool is_mnt_ns_file/i $(CAN_UMOUNT)' $(srctree)/fs/namespace.c;)
endif

ifneq ($(shell grep -Eq "^int path_umount" $(srctree)/fs/namespace.c; echo $$?),0)
$(info -- KSU_SUSFS: adding function 'int path_umount(struct path *path, int flags);' to $(srctree)/fs/namespace.c)
PATH_UMOUNT = int path_umount(struct path *path, int flags)\n\
{\n\t\
        struct mount *mnt = real_mount(path->mnt);\n\t\
        int ret;\n\t\
        ret = can_umount(path, flags);\n\t\
        if (!ret)\n\t\t\
                ret = do_umount(mnt, flags);\n\t\
        dput(path->dentry);\n\t\
        mntput_no_expire(mnt);\n\t\
        return ret;\n\
}\n
$(shell sed -i '/^static bool is_mnt_ns_file/i $(PATH_UMOUNT)' $(srctree)/fs/namespace.c;)
endif

ifneq ($(shell grep -Eq "^int path_umount" $(srctree)/fs/internal.h; echo $$?),0)
$(shell sed -i '/^extern void __init mnt_init/a int path_umount(struct path *path, int flags);' $(srctree)/fs/internal.h;)
$(info -- KSU_SUSFS: adding 'int path_umount(struct path *path, int flags);' to $(srctree)/fs/internal.h)
endif

## For susfs stuff ##
ifeq ($(shell test -e $(srctree)/fs/susfs.c; echo $$?),0)
$(eval SUSFS_VERSION=$(shell cat $(srctree)/include/linux/susfs.h | grep -E '^#define SUSFS_VERSION' | cut -d' ' -f3 | sed 's/"//g'))
$(info )
$(info -- SUSFS_VERSION: $(SUSFS_VERSION))
else
$(info -- You have not integrate susfs in your kernel.)
$(info -- Read: https://gitlab.com/simonpunk/susfs4ksu)
endif

# Keep a new line here!! Because someone may append config
