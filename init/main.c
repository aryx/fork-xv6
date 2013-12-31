#include "types.h"

#include "defs.h"

#include "param.h"
#include "mmu.h"
#include "proc.h"
#include "x86.h"

//***************************************************************************
// Prelude
//***************************************************************************

//***************************************************************************
// My main
//***************************************************************************

int my_main(void)
{
  DEBUG("MYMAIN\n");

}

//***************************************************************************
// Helpers
//***************************************************************************

//static void mpmain(void) __attribute__((noreturn));
//static void bootothers(void);


// Bootstrap processor gets here after setting up the hardware.
// Additional processors start here.
static void
mpmain(void)
{
  DEBUG("cpu%d: mpmain\n", cpu());
  idtinit();
  if(cpu() != mp_bcpu())
    lapic_init(cpu());
  setupsegs(0);
  xchg(&cpus[cpu()].booted, 1);

  DEBUG("cpu%d: scheduling\n", cpu());
  scheduler(); // <> sched()
}

// SMP
static void
bootothers(void)
{
  extern uchar _binary_bootother_start[], _binary_bootother_size[];
  uchar *code;
  struct cpu *c;
  char *stack;

  // Write bootstrap code to unused memory at 0x7000.
  code = (uchar*)0x7000;
  kmemmove(code, _binary_bootother_start, (uint)_binary_bootother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == cpus+cpu())  // We've started already.
      continue;

    // Fill in %esp, %eip and start code on cpu.
    stack = kalloc(KSTACKSIZE);
    *(void**)(code-4) = stack + KSTACKSIZE;
    *(void**)(code-8) = mpmain;
    lapic_startap(c->apicid, (uint)code);

    // Wait for cpu to get through bootstrap.
    while(c->booted == 0)
      ;
  }
}


//***************************************************************************
// Main entry point
//***************************************************************************

// Bootstrap processor starts running C code here.
int
main(void)
{
  extern char edata[], end[];

  //pad: makes OS crash, need to have memset first, why ???
  //DEBUG("ncpu = %d", ncpu);

  // clear BSS  pad: seems very important
  kmemset(edata, 0, end - edata);

  // Welcome
  cprintf("Welcome to XIX\n");

  DEBUG("loaded at %x, end = %x\n", &main, end);

  // SMP bootstrap
  DEBUG("ncpu = %d\n", ncpu);
  mp_init(); // collect info about this machine
  DEBUG("ncpu = %d\n", ncpu);
  lapic_init(mp_bcpu());
  DEBUG("\ncpu%d: starting xv6\n\n", cpu());


  // data structures initializations
  
  pinit();         // process table
  binit();         // buffer cache

  pic_init();      // interrupt controller
  ioapic_init();   // another interrupt controller, for SMP

  kinit();         // physical memory allocator
  tvinit();        // trap vectors
  fileinit();      // file table
  iinit();         // inode cache

  console_init();  // I/O devices & their interrupts
  ide_init();      // disk

  // this will do task switching at every 100ms
  if(!ismp)
    timer_init();  // uniprocessor timer

  my_main();


  // !!! first user process !!!
  userinit(); 

  // smp
  bootothers();    // start other processors

  // Finish setting up this processor in mpmain.
  mpmain(); // idtinit(), and call the scheduler()

  DEBUG("NEVER EXECUTED");
}
