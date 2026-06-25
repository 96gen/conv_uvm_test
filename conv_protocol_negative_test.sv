class conv_protocol_negative_test extends conv_test;
    `uvm_component_utils(conv_protocol_negative_test)

    function new(string name = "conv_protocol_negative_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        item_count = 1;
        expected_ready_count = 2;
        inject_ready_while_busy = 1;
        super.build_phase(phase);
    endfunction
endclass
