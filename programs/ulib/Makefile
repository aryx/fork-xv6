TOP=../..

#############################################################################
# Configuration section
#############################################################################

# compilers, debugging, etc
-include $(TOP)/Makefile.config

INCLUDEDIRS=$(TOP)/include
INCLUDES=$(INCLUDEDIRS:%=-I %)

CFLAGS+=$(INCLUDES)
ASFLAGS+=$(INCLUDES)

#############################################################################
# User programs
#############################################################################

all: ulib.a

ulib.a: ulib.o usys.o printf.o umalloc.o
	$(AR) r $@ $^

clean::
	rm -f *.o *.a

depend:
	$(NATIVEGCC) $(INCLUDES)  -MM *.c *.S > .depend

-include .depend


