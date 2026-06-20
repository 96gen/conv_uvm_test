class conv_l0_mem_feedback_smoke_test extends conv_layer1_path_smoke_test;
    `uvm_component_utils(conv_l0_mem_feedback_smoke_test)

    function new(string name = "conv_l0_mem_feedback_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass