#include "timer.h"
#include "csr.h"
#include <sys/times.h>

//-----------------------------------------------------------------
// cpu_timer_get_count:
//-----------------------------------------------------------------
static inline unsigned long cpu_timer_get_count(void)
{    
    unsigned long value;
    asm volatile ("csrr %0, cycle" : "=r" (value) : );
    return value;
}
//--------------------------------------------------------------------------
// timer_init:
//--------------------------------------------------------------------------
void timer_init(void)
{

}
//--------------------------------------------------------------------------
// timer_sleep:
//--------------------------------------------------------------------------
void timer_sleep(int timeMs)
{
    t_time t = cpu_timer_get_count();

    while (timer_diff(cpu_timer_get_count(), t) < (timeMs*CPU_KHZ))
        ;
}
//--------------------------------------------------------------------------
// timer_now:
//--------------------------------------------------------------------------
t_time timer_now(void)
{
	return cpu_timer_get_count();
}
//--------------------------------------------------------------------------
// timer_set_mtimecmp: Non-std mtimecmp support
//--------------------------------------------------------------------------
void timer_set_mtimecmp(t_time next)
{
    csr_write(0x7c0, next);
}
//--------------------------------------------------------------------------
// timer_get_mtime:
//--------------------------------------------------------------------------
t_time timer_get_mtime(void)
{
    return csr_read(0xc00);
}