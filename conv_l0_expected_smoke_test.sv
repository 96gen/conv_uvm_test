class conv_l0_expected_smoke_test extends conv_l0_mem_feedback_smoke_test;
    `uvm_component_utils(conv_l0_expected_smoke_test)

    function new(string name = "conv_l0_expected_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        check_l0_expected = 1;
        expected_l0_file = "cnn_layer0_exp0.dat";
        expected_l0_compare_count = 4096;
        super.build_phase(phase);
    endfunction
endclass