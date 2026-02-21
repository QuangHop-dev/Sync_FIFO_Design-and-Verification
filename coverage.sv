// Explore VLSI Youtube Channel //

`ifndef FIFO_COVERAGE_SV
`define FIFO_COVERAGE_SV

// FIFO Functional Coverage Collector
// - Connect this to monitor's analysis port (ap)
// - Samples wr/rd/full/empty and basic data distributions

class fifo_coverage extends uvm_subscriber#(fifo_seq_item);

  `uvm_component_utils(fifo_coverage)

  // -----------------------------
  // Covergroups
  // -----------------------------

  // Control/status coverage
  covergroup cg_ctrl with function sample(fifo_seq_item t);
    option.per_instance = 1;

    cp_wr   : coverpoint t.wr   { bins wr0 = {0}; bins wr1 = {1}; }
    cp_rd   : coverpoint t.rd   { bins rd0 = {0}; bins rd1 = {1}; }

    // State + transition bins (helps show you exercised boundary conditions)
    cp_full : coverpoint t.full {
      bins f0      = {0};
      bins f1      = {1};
      bins f_rise  = (0 => 1);
      bins f_fall  = (1 => 0);
    }

    cp_empty : coverpoint t.empty {
      bins e0      = {0};
      bins e1      = {1};
      bins e_rise  = (0 => 1);
      bins e_fall  = (1 => 0);
    }

    // Operation type derived from {wr,rd}
    cp_op : coverpoint {t.wr, t.rd} {
      bins idle  = {2'b00};
      bins write = {2'b10};
      bins read  = {2'b01};
      bins both  = {2'b11};
    }

    // Useful crosses
    x_op_full  : cross cp_op, cp_full;
    x_op_empty : cross cp_op, cp_empty;
    x_all      : cross cp_wr, cp_rd, cp_full, cp_empty;

  endgroup

  // Data-in coverage (only meaningful on writes)
  covergroup cg_din with function sample(fifo_seq_item t);
    option.per_instance = 1;

    cp_din : coverpoint t.data_in iff (t.wr) {
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins low  = {[8'h01:8'h0F]};
      bins mid  = {[8'h10:8'hEF]};
      bins high = {[8'hF0:8'hFE]};
    }

  endgroup

  // Data-out coverage (only meaningful on successful reads)
  covergroup cg_dout with function sample(fifo_seq_item t);
    option.per_instance = 1;

    cp_dout : coverpoint t.data_out iff (t.rd && !t.empty) {
      bins zero = {8'h00};
      bins ones = {8'hFF};
      bins low  = {[8'h01:8'h0F]};
      bins mid  = {[8'h10:8'hEF]};
      bins high = {[8'hF0:8'hFE]};
    }

  endgroup

  // Protocol “corner/illegal attempt” coverage (not assertion, just measure)
  covergroup cg_illegal with function sample(fifo_seq_item t);
    option.per_instance = 1;

    cp_illegal : coverpoint 1'b1 {
      bins wr_when_full  = {1} iff (t.wr && t.full);
      bins rd_when_empty = {1} iff (t.rd && t.empty);
    }

  endgroup

  // -----------------------------
  // Constructor
  // -----------------------------
  function new(string name = "fifo_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_ctrl    = new();
    cg_din     = new();
    cg_dout    = new();
    cg_illegal = new();
  endfunction

  // -----------------------------
  // Subscriber write()
  // -----------------------------
  virtual function void write(fifo_seq_item t);
    if (t == null) return;

    cg_ctrl.sample(t);
    cg_din.sample(t);
    cg_dout.sample(t);
    cg_illegal.sample(t);
  endfunction

  // -----------------------------
  // Report coverage summary
  // -----------------------------
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("FIFO_COV", $sformatf("cg_ctrl    = %0.2f%%", cg_ctrl.get_inst_coverage()), UVM_LOW)
    `uvm_info("FIFO_COV", $sformatf("cg_din     = %0.2f%%", cg_din.get_inst_coverage()), UVM_LOW)
    `uvm_info("FIFO_COV", $sformatf("cg_dout    = %0.2f%%", cg_dout.get_inst_coverage()), UVM_LOW)
    `uvm_info("FIFO_COV", $sformatf("cg_illegal = %0.2f%%", cg_illegal.get_inst_coverage()), UVM_LOW)
  endfunction

endclass

`endif // FIFO_COVERAGE_SV
