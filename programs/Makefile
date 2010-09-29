TOP=..

#############################################################################
# Configuration section
#############################################################################

# compilers, debugging, etc
-include $(TOP)/Makefile.config

INCLUDEDIRS=../include
INCLUDES=$(INCLUDEDIRS:%=-I %)

CFLAGS+=$(INCLUDES)
ASFLAGS+=$(INCLUDES)

#############################################################################
# Variables
#############################################################################

UPROGS=\
	_cat\
	_echo\
	_forktest\
	_grep\
	_init\
	_kill\
	_ln\
	_ls\
	_mkdir\
	_rm\
	_sh\
	_usertests\
	_wc\
	_zombie\

LIBS = ulib/ulib.a

SUBDIRS=ulib

#############################################################################
# Top rules
#############################################################################

all: rec $(UPROGS)

_%: %.o $(LIBS)
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o $@ $^

# forktest has less library code linked in - needs to be small
# in order to be able to max out the proc table.
_forktest: forktest.o $(ULIB)
	$(LD) $(LDFLAGS) -N -e main -Ttext 0 -o _forktest forktest.o ulib/ulib.o ulib/usys.o

clean::
	rm -f $(UPROGS)


rec:
	for i in $(SUBDIRS); do make -C $$i; done 
depend::
	for i in $(SUBDIRS); do make -C $$i depend; done 
clean::
	for i in $(SUBDIRS); do make -C $$i clean; done 


-include $(TOP)/Makefile.common



depend::
	$(NATIVEGCC) $(INCLUDES)  -MM *.c > .depend

-include .depend
