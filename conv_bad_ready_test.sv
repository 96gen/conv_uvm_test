class conv_bad_ready_test extends conv_test;
    `uvm_component_utils(conv_bad_ready_test);

    function new(string name = "conv_bad_ready_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        uvm_config_db#(bit)::set(this, "*", "inject_bad_ready_tr", 1'b1);
        super.build_phase(phase);
    endfunction
endclass
