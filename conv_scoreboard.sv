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
        `uvm_info("CONV_SCOREBOARD", "received transaction", UVM_LOW)
    endfunction
endclass
