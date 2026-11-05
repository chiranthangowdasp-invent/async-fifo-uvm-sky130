quit -sim
vlib work
vlog -sv -timescale 1ns/1ps +incdir+tb rtl/sync_2ff.v rtl/fifo_mem.v rtl/wptr_full.v rtl/rptr_empty.v rtl/async_fifo.v tb/fifo_if.sv tb/fifo_pkg.sv tb/tb_top.sv
vsim -voptargs=+acc work.tb_top +UVM_TESTNAME=$1
add wave -r /tb_top/*
run -all
