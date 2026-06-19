class conv_scoreboard extends uvm_component;
    `uvm_component_utils(conv_scoreboard);
    int observed_count = 0;
    int received_count = 0;
    int expected_ready_count = 3;
    uvm_analysis_imp #(conv_mem_wr_tr, conv_scoreboard) imp;

    function new(string name = "conv_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
        void'(uvm_config_db#(int)::get(this, "", "expected_ready_count", expected_ready_count));
    endfunction

    function void write(conv_mem_wr_tr tr);
        observed_count = observed_count + 1;
        if (!tr.ready_seen) begin
            `uvm_error("CONV_SCOREBOARD", "expected ready_seen transaction")
        end
        else begin
            received_count = received_count + 1;
            `uvm_info("CONV_SCOREBOARD", "ready transaction check passed", UVM_LOW)
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (observed_count  != expected_ready_count) begin
            `uvm_error("CONV_SCOREBOARD",
                $sformatf("expected ready count=%0d actual=%0d",
                          expected_ready_count, observed_count ))
        end
        else begin
            `uvm_info("CONV_SCOREBOARD",
                $sformatf("received expected ready count=%0d", observed_count ),
                UVM_LOW)
        end
    endfunction
endclass
