#############################################################################
# Configuration section
#############################################################################

# compilers, debugging, etc
-include Makefile.config

INCLUDEDIRS=include
INCLUDES=$(INCLUDEDIRS:%=-I %)

CFLAGS+=$(INCLUDES)
ASFLAGS+=$(INCLUDES)

#############################################################################
# The kernel
#############################################################################

OBJS = \
	lib/string.o\
	arch/kern/swtch.o\
	arch/kern/trapasm.o\
	arch/kern/vectors.o\
	kern/hardware/ioapic.o\
	kern/buffer.o\
	kern/exec.o\
	kern/mp.o\
	kern/spinlock.o\
	kern/syscall.o\
	kern/sysfile.o\
	kern/sysproc.o\
	kern/hardware/timer.o\
	kern/trap.o\
	kern/hardware/lapic.o\
	kern/hardware/picirq.o\
	fs/file.o\
	kern/pipe.o\
	mm/kalloc.o\
	drivers/console.o\
	kern/proc.o\
	fs/fs.o\
	drivers/ide.o\
	drivers/kbd.o\
	init/main.o\

SUBDIRS=lib arch/kern kern kern/hardware drivers fs init mm

#############################################################################
# Toplevel
#############################################################################

all: bootblock kernel fs.img xv6.img

#############################################################################
# Building the kernel
#############################################################################

#----------------------------------------------------------------------------
# bootloader
#----------------------------------------------------------------------------

#pad: need -O to generate a smaller than 512 bytes program
#pad: need also the -j .text otherwise not small enough
# sign.pl makes bootblock a valid bootsect, with the magic 55AA at the end
bootblock: arch/boot/bootasm.S arch/boot/bootmain.c
	$(CC) $(CFLAGS) -O -c arch/boot/bootasm.S
	$(CC) $(CFLAGS) -O -c arch/boot/bootmain.c
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o bootblock.o bootasm.o bootmain.o
	$(OBJCOPY) -S -O binary -j .text  bootblock.o bootblock
	scripts/sign.pl bootblock

#----------------------------------------------------------------------------
# special embedded low level progs
#----------------------------------------------------------------------------

# here are 2 programs linked with the kernel. They are not linked
# as regular kernel obj because they require special -Ttext and so
# are loaded manually from the kernel when needed
# TODO if put -Ttext 4  then does not work ... even when also adjust proc.c
#  accordingly

# first process
initcode: init/initcode.S
	$(CC) $(CFLAGS) -c $^
	$(LD) $(LDFLAGS) -N -e start -Ttext 0      -o initcode.out initcode.o
	$(OBJCOPY) -S -O binary initcode.out initcode

# for SMP initialization
bootother: init/bootother.S
	$(CC) $(CFLAGS) -c $^
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7000 -o bootother.out bootother.o
	$(OBJCOPY) -S -O binary bootother.out bootother

#----------------------------------------------------------------------------
# !!! The kernel!!!
#----------------------------------------------------------------------------

# set -Ttext to a portion after video RAM (0xb8000) at least
# TODO if 0xffff0 then pb, why?? if 0xfffff then ok
# was just -Ttext 0xfffff, no -T link.ld
kernel: $(OBJS) initcode bootother
	$(LD) $(LDFLAGS) -Ttext 0xfffff -e main -o kernel \
          $(OBJS) \
          -b binary    bootother initcode

#----------------------------------------------------------------------------
# Final image
#----------------------------------------------------------------------------
xv6.img: bootblock kernel
	dd if=/dev/zero of=xv6.img count=10000
	dd if=bootblock of=xv6.img conv=notrunc
	dd if=kernel of=xv6.img seek=1 conv=notrunc




clean::
	rm -f xv6.img bootblock bootother initcode kernel 


arch/kern/vectors.S: scripts/vectors.pl
	perl scripts/vectors.pl > arch/kern/vectors.S
clean::
	rm -f arch/kern/vectors.S



clean::
	for i in $(SUBDIRS); do (cd $$i; rm -f *.[od]); done 


#############################################################################
# User programs and fs image
#############################################################################

#pad: problematic, can not native compile it and run it :(
mkfs: scripts/mkfs.c include/fs.h
	$(NATIVEGCC) -fno-builtin -MD -Wall -Iinclude -o mkfs scripts/mkfs.c

UPROGS= $(wildcard programs/*.c)

list_uprogs:
	echo $(UPROGS)

fs.img: mkfs readme.txt $(UPROGS)
	make -C programs
	cp programs/_* .
	./mkfs fs.img   readme.txt _*

clean::
	rm -f mkfs fs.img 
	make -C programs clean
	rm -f _*



#############################################################################
# Generic rules
#############################################################################

-include Makefile.common

#TODO
-include *.d

clean::
	rm -f *.o *.d *.asm *.sym 
	rm -f *.out

#############################################################################
# For developers
#############################################################################

tags: 
	find -type f | xargs etags.emacs

wc:
	wc -l *.[cSh] */*.[cSh] */*/*.[cSh]
# => 7976

#############################################################################
# Literate programming
#############################################################################

# make a printout
#FILES = $(shell grep -v '^\#' runoff.list)
#PRINT = runoff.list $(FILES)

xv6.pdf: $(PRINT)
	./runoff

print: xv6.pdf

clean:: 
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg

#############################################################################
# Tests, emulators
#############################################################################
.PHONY:qemu

#fs.img xv6.img
qemu: 
	qemu-system-i386 -parallel stdio -hdb fs.img xv6.img

bochs : fs.img xv6.img
	if [ ! -e .bochsrc ]; then ln -s dot-bochsrc .bochsrc; fi
	bochs -q



qemusmp: fs.img xv6.img
	qemu -smp 2 -parallel stdio -hdb fs.img xv6.img

