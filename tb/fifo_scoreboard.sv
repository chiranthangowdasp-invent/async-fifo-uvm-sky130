`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp_wr #(fifo_txn, fifo_scoreboard) wr_imp;
  uvm_analysis_imp_rd #(fifo_txn, fifo_scoreboard) rd_imp;

  bit [7:0]    expected_q[$];     // reference model: a plain queue
  int unsigned n_wr, n_rd, n_err;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_imp = new("wr_imp", this);
    rd_imp = new("rd_imp", this);
  endfunction

  // called by the write monitor for every accepted write
  function void write_wr(fifo_txn t);
    expected_q.push_back(t.data);
    n_wr++;
  endfunction

  // called by the read monitor for every accepted read
  function void write_rd(fifo_txn t);
    bit [7:0] exp;
    n_rd++;
    if (expected_q.size() == 0) begin
      `uvm_error("SCB", $sformatf("read 0x%02h but nothing was written (underflow)", t.data))
      n_err++;
      return;
    end
    exp = expected_q.pop_front();
    if (t.data !== exp) begin
      `uvm_error("SCB", $sformatf("MISMATCH expected 0x%02h got 0x%02h", exp, t.data))
      n_err++;
    end else
      `uvm_info("SCB", $sformatf("match 0x%02h", t.data), UVM_MEDIUM)
  endfunction

  function void flush();          // called by a test after it resets the FIFO
    expected_q.delete();
  endfunction

  function void check_phase(uvm_phase phase);
    if (expected_q.size() != 0)
      `uvm_error("SCB", $sformatf("%0d entries written but never read", expected_q.size()))
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("SUMMARY writes=%0d reads=%0d errors=%0d", n_wr, n_rd, n_err), UVM_NONE)
  endfunction
endclass
