class conv_short_ready_test extends conv_test;
    `uvm_component_utils(conv_short_ready_test);

    function new(string name = "conv_short_ready_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        item_count = 1;
        expected_ready_count = 1;
        super.build_phase(phase);
    endfunction
endclass
