class conv_protocol_csel_fault_test extends conv_test;
    `uvm_component_utils(conv_protocol_csel_fault_test)

    function new(string name = "conv_protocol_csel_fault_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        item_count = 1;
        expected_ready_count = 1;
        img_file = "cnn_sti.dat";
        dat_sample_words = 4;
        drive_dut_input = 1;
        dut_drive_cycles = 1700;
        dut_drive_log_stride = 256;
        expected_l0_write_min = 1;
        super.build_phase(phase);
    endfunction
endclass
