# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2020  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


pre := lib
dll := so
lib := a
exe := 

ifeq ($(libc),)
libc := gnu
endif

meson := linux

archs += x86_64
openssl/x86_64 := linux-x86_64
host/x86_64 := x86_64-linux-$(libc)
triple/x86_64 := x86_64-unknown-linux-$(libc)
meson/x86_64 := x86_64

archs += aarch64
openssl/aarch64 := linux-aarch64
host/aarch64 := aarch64-linux-$(libc)
triple/aarch64 := aarch64-unknown-linux-$(libc)
meson/aarch64 := aarch64

archs += mips
openssl/mips := linux-mips32
host/mips := mips-linux-$(libc)
triple/mips := mips-unknown-linux-$(libc)
meson/mips := mips

include $(pwd)/target-elf.mk
lflags += -Wl,--hash-style=gnu

ifeq ($(filter crossndk,$(debug))$(uname-s),Linux)

define _
ranlib/$(1) := ranlib
ar/$(1) := ar
strip/$(1) := strip
windres/$(1) := false
endef
$(each)

cc := clang$(suffix)
cxx := clang++$(suffix)

cxx += -stdlib=libc++

tidy := $(shell which clang-tidy 2>/dev/null)
ifeq ($(tidy)$(filter notidy,$(debug)),)
debug += notidy
endif

else

more := 
more += --sysroot $(CURDIR)/$(output)/sysroot
more += --gcc-toolchain=$(CURDIR)/$(output)/sysroot/usr
include $(pwd)/target-ndk.mk
include $(pwd)/target-cxx.mk

lflags += -lrt

define _
more/$(1) := 
more/$(1) += -B$(llvm)/$(1)-linux-android/bin
more/$(1) += -target $(1)-linux-$(libc)
ranlib/$(1) := $(llvm)/bin/llvm-ranlib
ar/$(1) := $(llvm)/bin/llvm-ar
strip/$(1) := $(llvm)/bin/$(1)-linux-android-strip
windres/$(1) := false
# XXX: this check is horrible and doesn't _usually_ work
# https://github.com/rust-lang/cargo/issues/8147
ifeq ($(uname-s)-$(1),Linux-x86_64)
ccrs/$(1) := HOST
endif
export CARGO_TARGET_$(subst -,_,$(call uc,$(triple/$(1))))_RUSTFLAGS := $$(foreach arg,$(wordlist 2,$(words $(cc)),$(cc)) $$(more/$(1)),-C link-arg=$$(arg)) $(rflags)
export CARGO_TARGET_$(subst -,_,$(call uc,$(triple/$(1))))_LINKER := $(firstword $(cc))
endef
$(each)

ifeq ($(distro),)
distro := centos6
endif

$(output)/sysroot: env/sys-$(word 1,$(distro)).sh env/setup-sys.sh
	$< $@ $(wordlist 2,$(words $(distro)),$(distro))
	@touch $@

.PHONY: sysroot
sysroot: $(output)/sysroot

sysroot += $(output)/sysroot

endif

lflags += -ldl
lflags += -pthread

default := x86_64
