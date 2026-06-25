class conv_reset_protocol_fault_test extends conv_test;
    `uvm_component_utils(conv_reset_protocol_fault_test)

    function new(string name = "conv_reset_protocol_fault_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        item_count = 0;
        expected_ready_count = 0;
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        vif.ready <= 1'b0;
        vif.reset <= 1'b1;
        repeat (5) @(posedge vif.clk);
        @(negedge vif.clk);
        phase.drop_objection(this);
    endtask
endclass
