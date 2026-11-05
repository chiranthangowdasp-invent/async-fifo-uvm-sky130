// ---------- Sequences ----------
class write_seq extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(write_seq)
  int unsigned n = 5;
  bit force_op = 0;
  function new(string name = "write_seq"); super.new(name); endfunction
  task body();
    repeat (n) begin
      fifo_txn t = fifo_txn::type_id::create("t");
      start_item(t);
      t.data = $urandom_range(0,255); t.idle_cycles = $urandom_range(0,3);
      t.force_op = force_op;
      finish_item(t);
    end
  endtask
endclass

class read_seq extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(read_seq)
  int unsigned n = 5;
  bit force_op = 0;
  function new(string name = "read_seq"); super.new(name); endfunction
  task body();
    repeat (n) begin
      fifo_txn t = fifo_txn::type_id::create("t");
      start_item(t);
      t.data = $urandom_range(0,255); t.idle_cycles = $urandom_range(0,3);
      t.force_op = force_op;
      finish_item(t);
    end
  endtask
endclass

// ---------- Base test: builds the env and gives helper tasks ----------
class fifo_base_test extends uvm_test;
  `uvm_component_utils(fifo_base_test)
  fifo_env        env;
  virtual fifo_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "test: virtual interface not set")
  endfunction

  task do_writes(int unsigned n, bit force_op = 0);
    write_seq s = write_seq::type_id::create("wseq");
    s.n = n; s.force_op = force_op;
    @(vif.wcb);                    // begin on a write-clock edge
    s.start(env.wagent.sqr);
  endtask

  task do_reads(int unsigned n, bit force_op = 0);
    read_seq s = read_seq::type_id::create("rseq");
    s.n = n; s.force_op = force_op;
    @(vif.rcb);                    // begin on a read-clock edge
    s.start(env.ragent.sqr);
  endtask

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("TEST", $sformatf("blocked write attempts=%0d, blocked read attempts=%0d", vif.wr_blocked, vif.rd_blocked), UVM_NONE)
  endfunction

  task settle();       // let pointers cross both synchronizers
    #100ns;
  endtask
endclass

// ---------- Test 1: basic write then read ----------
class basic_rw_test extends fifo_base_test;
  `uvm_component_utils(basic_rw_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "basic_rw_test: write 8 words, then read 8 words", UVM_NONE)
    do_writes(8);
    settle();
    if (vif.rempty) `uvm_error("TEST", "rempty still high after 8 writes")
    do_reads(8);
    settle();
    if (!vif.rempty) `uvm_error("TEST", "rempty not high after draining")
    phase.drop_objection(this);
  endtask
endclass

// ---------- Test 2: fill to full ----------
class fill_full_test extends fifo_base_test;
  `uvm_component_utils(fill_full_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "fill_full_test: fill 16 entries, over-write, then drain", UVM_NONE)
    wait (vif.wrst_n === 1'b1 && vif.rrst_n === 1'b1);
    settle();
    if (vif.rempty !== 1'b1 || vif.wfull !== 1'b0)
      `uvm_error("TEST", "after reset expected rempty=1 and wfull=0")

    do_writes(16);                         // exactly the FIFO depth
    settle();
    if (vif.wfull !== 1'b1)
      `uvm_error("TEST", "wfull not set after writing 16 entries")

    do_writes(3, 1);                       // 3 forced writes into a full FIFO: must be blocked
    settle();
    if (vif.wfull !== 1'b1)
      `uvm_error("TEST", "wfull dropped after over-write attempts")

    do_reads(16);                          // the original 16 words must come out intact
    settle();
    if (vif.wfull !== 1'b0)
      `uvm_error("TEST", "wfull still set after draining")
    if (vif.rempty !== 1'b1)
      `uvm_error("TEST", "rempty not set after draining")
    phase.drop_objection(this);
  endtask
endclass

// ---------- Test 3: drain to empty ----------
class drain_empty_test extends fifo_base_test;
  `uvm_component_utils(drain_empty_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "drain_empty_test: drain, under-read, then reuse the FIFO", UVM_NONE)
    wait (vif.wrst_n === 1'b1 && vif.rrst_n === 1'b1);
    settle();

    do_writes(6);
    settle();
    do_reads(6);
    settle();
    if (vif.rempty !== 1'b1)
      `uvm_error("TEST", "rempty not set after draining 6 entries")

    do_reads(3, 1);                        // 3 forced reads from an empty FIFO: must be blocked
    settle();
    if (vif.rempty !== 1'b1)
      `uvm_error("TEST", "rempty dropped after under-read attempts")

    do_writes(4);                          // the FIFO must still work normally afterwards
    settle();
    if (vif.rempty !== 1'b0)
      `uvm_error("TEST", "rempty still set after 4 new writes")
    do_reads(4);
    settle();
    if (vif.rempty !== 1'b1)
      `uvm_error("TEST", "rempty not set after final drain")
    phase.drop_objection(this);
  endtask
endclass

// ---------- Test 4: fast write clock, slow read clock ----------
class fast_write_slow_read_test extends fifo_base_test;
  `uvm_component_utils(fast_write_slow_read_test)
  bit saw_full = 0;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "fast_write_slow_read_test: 250 MHz write, 50 MHz read, 64 words", UVM_NONE)
    wait (vif.wrst_n === 1'b1 && vif.rrst_n === 1'b1);
    settle();
    vif.whalf = 2.0;                       // 4 ns write clock
    vif.rhalf = 10.0;                      // 20 ns read clock

    fork                                   // background watcher: did the FIFO ever fill up?
      forever begin
        @(posedge vif.wfull);
        saw_full = 1;
      end
    join_none

    fork                                   // writer and reader run at the same time
      do_writes(64);
      do_reads(64);
    join
    settle();
    if (!saw_full)
      `uvm_error("TEST", "expected wfull to assert at least once (writer is 5x faster)")
    if (vif.rempty !== 1'b1)
      `uvm_error("TEST", "rempty not set after all data was read")
    phase.drop_objection(this);
  endtask
endclass

// ---------- Test 5: slow write clock, fast read clock, mid-test reset ----------
class slow_write_fast_read_reset_test extends fifo_base_test;
  `uvm_component_utils(slow_write_fast_read_reset_test)
  int unsigned empty_events = 0;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "slow_write_fast_read_reset_test: 50 MHz write, 250 MHz read, then reset", UVM_NONE)
    wait (vif.wrst_n === 1'b1 && vif.rrst_n === 1'b1);
    settle();
    vif.whalf = 10.0;                      // 20 ns write clock
    vif.rhalf = 2.0;                       // 4 ns read clock

    fork                                   // count how often the FIFO runs empty
      forever begin
        @(posedge vif.rempty);
        empty_events++;
      end
    join_none

    // Phase A: concurrent traffic, reader much faster than writer
    fork
      do_writes(32);
      do_reads(32);
    join
    settle();
    if (empty_events == 0)
      `uvm_error("TEST", "expected rempty to re-assert (reader is 5x faster)")

    // Phase B: leave data in the FIFO, then reset both domains
    do_writes(10);
    settle();
    if (vif.rempty !== 1'b0)
      `uvm_error("TEST", "rempty should be low with 10 entries inside")
    vif.wrst_n = 0; vif.rrst_n = 0;
    #100ns;
    vif.wrst_n = 1; vif.rrst_n = 1;
    env.scb.flush();                       // the FIFO lost its data, so the model must too
    settle();
    if (vif.rempty !== 1'b1 || vif.wfull !== 1'b0)
      `uvm_error("TEST", "after mid-test reset expected rempty=1 and wfull=0")

    // Phase C: the FIFO must behave like new, with no stale data
    fork
      do_writes(8);
      do_reads(8);
    join
    settle();
    phase.drop_objection(this);
  endtask
endclass
