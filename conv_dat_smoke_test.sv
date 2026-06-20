class conv_dat_smoke_test extends conv_test;
    `uvm_component_utils(conv_dat_smoke_test);

    function new(string name = "conv_dat_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        item_count = 1;
        expected_ready_count = 1;
        img_file = "cnn_sti.dat";
        dat_sample_words = 4;
        super.build_phase(phase);
    endfunction
endclass
