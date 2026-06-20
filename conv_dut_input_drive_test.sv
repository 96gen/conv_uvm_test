class conv_dut_input_drive_test extends conv_test;
    `uvm_component_utils(conv_dut_input_drive_test)

    function new(string name = "conv_dut_input_drive_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        item_count = 1;
        expected_ready_count = 1;
        img_file = "cnn_sti.dat";
        dat_sample_words = 4;
        drive_dut_input = 1;
        dut_drive_cycles = 32;
        super.build_phase(phase);
    endfunction
endclass