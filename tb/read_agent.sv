// ---------------- Driver ----------------
class read_driver extends uvm_driver #(fifo_txn);
  `uvm_component_utils(read_driver)
  virtual fifo_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "read_driver: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.rrst_n === 1'b1);
    @(vif.rcb);
    forever begin
      seq_item_port.get_next_item(req);
      repeat (req.idle_cycles) begin
        vif.rcb.rinc <= 1'b0;
        @(vif.rcb);
      end
      do begin                            // hold rinc until the read is accepted
        vif.rcb.rinc <= 1'b1;
        @(vif.rcb);
      end while (vif.rcb.rempty && !req.force_op);
      vif.rcb.rinc <= 1'b0;
      seq_item_port.item_done();
    end
  endtask
endclass

// ---------------- Monitor ----------------
class read_monitor extends uvm_monitor;
  `uvm_component_utils(read_monitor)
  virtual fifo_if vif;
  uvm_analysis_port #(fifo_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "read_monitor: virtual interface not set")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_txn t;
    wait (vif.rrst_n === 1'b1);
    forever begin
      @(vif.rmon);
      if (vif.rmon.rinc && !vif.rmon.rempty) begin   // a read really happened
        t = fifo_txn::type_id::create("rd_t");
        t.data = vif.rmon.rdata;                     // value shown at the edge
        `uvm_info("RMON", $sformatf("read accepted data=0x%02h", t.data), UVM_LOW)
        ap.write(t);
      end
    end
  endtask
endclass

// ---------------- Agent ----------------
class read_agent extends uvm_agent;
  `uvm_component_utils(read_agent)
  read_driver    drv;
  read_monitor   mon;
  fifo_sequencer sqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = read_monitor::type_id::create("mon", this);
    drv = read_driver::type_id::create("drv", this);
    sqr = fifo_sequencer::type_id::create("sqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
