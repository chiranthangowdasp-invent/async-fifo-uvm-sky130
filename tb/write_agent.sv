typedef uvm_sequencer #(fifo_txn) fifo_sequencer;

// ---------------- Driver ----------------
class write_driver extends uvm_driver #(fifo_txn);
  `uvm_component_utils(write_driver)
  virtual fifo_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "write_driver: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.wrst_n === 1'b1);          // do nothing during reset
    @(vif.wcb);
    forever begin
      seq_item_port.get_next_item(req);
      repeat (req.idle_cycles) begin     // idle gap: winc low
        vif.wcb.winc <= 1'b0;
        @(vif.wcb);
      end
      do begin                           // hold the request until it is accepted
        vif.wcb.winc  <= 1'b1;
        vif.wcb.wdata <= req.data;
        @(vif.wcb);
      end while (vif.wcb.wfull && !req.force_op);         // if FIFO was full at that edge, try again
      vif.wcb.winc <= 1'b0;
      seq_item_port.item_done();
    end
  endtask
endclass

// ---------------- Monitor ----------------
class write_monitor extends uvm_monitor;
  `uvm_component_utils(write_monitor)
  virtual fifo_if vif;
  uvm_analysis_port #(fifo_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "write_monitor: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_txn t;
    wait (vif.wrst_n === 1'b1);
    forever begin
      @(vif.wmon);
      if (vif.wmon.winc && !vif.wmon.wfull) begin   // a write really happened
        t = fifo_txn::type_id::create("wr_t");
        t.data = vif.wmon.wdata;
        `uvm_info("WMON", $sformatf("write accepted data=0x%02h", t.data), UVM_LOW)
        ap.write(t);
      end
    end
  endtask
endclass

// ---------------- Agent ----------------
class write_agent extends uvm_agent;
  `uvm_component_utils(write_agent)
  write_driver    drv;
  write_monitor   mon;
  fifo_sequencer  sqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = write_monitor::type_id::create("mon", this);
    drv = write_driver::type_id::create("drv", this);
    sqr = fifo_sequencer::type_id::create("sqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
