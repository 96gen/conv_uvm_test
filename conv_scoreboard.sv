class conv_scoreboard extends uvm_component;
    `uvm_component_utils(conv_scoreboard);
    uvm_analysis_imp #(conv_mem_wr_tr, conv_scoreboard) imp;

    function new(string name = "conv_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
    endfunction

    function void write(conv_mem_wr_tr tr);
        if (!tr.ready_seen) begin
            `uvm_error("CONV_SCOREBOARD", "expected ready_seen transaction")
        end
        else begin
            `uvm_info("CONV_SCOREBOARD", "ready transaction check passed", UVM_LOW)
        end
    endfunction
endclass
