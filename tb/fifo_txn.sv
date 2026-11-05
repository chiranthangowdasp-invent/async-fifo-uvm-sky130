class fifo_txn extends uvm_sequence_item;
  `uvm_object_utils(fifo_txn)

  rand bit [7:0]    data;         // payload (writes), or filled in by the read monitor
  rand int unsigned idle_cycles;  // clock cycles to wait before this operation
  bit               force_op = 0; // 1 = try once, don't wait if the FIFO blocks it

  constraint c_idle { idle_cycles inside {[0:3]}; }

  function new(string name = "fifo_txn");
    super.new(name);
  endfunction

  function string convert2string();
    return $sformatf("data=0x%02h idle=%0d force=%0b", data, idle_cycles, force_op);
  endfunction
endclass
