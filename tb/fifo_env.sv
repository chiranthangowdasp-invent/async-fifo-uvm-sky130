class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)
  write_agent     wagent;
  read_agent      ragent;
  fifo_scoreboard scb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wagent = write_agent::type_id::create("wagent", this);
    ragent = read_agent::type_id::create("ragent", this);
    scb    = fifo_scoreboard::type_id::create("scb", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    wagent.mon.ap.connect(scb.wr_imp);
    ragent.mon.ap.connect(scb.rd_imp);
  endfunction
endclass
