@echo off
if not exist logs mkdir logs
if not exist work vlib work
vlog -sv -timescale 1ns/1ps +incdir+tb rtl/sync_2ff.v rtl/fifo_mem.v rtl/wptr_full.v rtl/rptr_empty.v rtl/async_fifo.v tb/fifo_if.sv tb/fifo_pkg.sv tb/tb_top.sv || exit /b 1
for %%T in (basic_rw_test fill_full_test drain_empty_test fast_write_slow_read_test slow_write_fast_read_reset_test) do (
  vsim -c -l logs\%%T.log -wlf logs\%%T.wlf -voptargs=+acc work.tb_top +UVM_TESTNAME=%%T -do "run -all; quit -f"
)
echo ===== RESULTS =====
findstr /C:"UVM_ERROR :" /C:"UVM_FATAL :" /C:"SUMMARY" /C:"Error" logs\*.log
