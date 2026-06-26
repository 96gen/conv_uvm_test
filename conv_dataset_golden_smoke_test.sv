class conv_dataset_golden_smoke_test extends conv_test;
    `uvm_component_utils(conv_dataset_golden_smoke_test)

    function new(string name = "conv_dataset_golden_smoke_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        item_count = 1;
        expected_ready_count = 1;
        img_file = "cnn_sti.dat";
        dat_sample_words = 4;
        drive_dut_input = 1;
        dut_drive_cycles = 62000;
        dut_drive_log_stride = 512;
        expected_l0_write_min = 4096;
        expected_l0_read_min = 4096;
        expected_l1_write_min = 1024;
        check_l0_expected = 1;
        expected_l0_file = "cnn_layer0_exp0.dat";
        expected_l0_compare_count = 4096;
        check_l1_expected = 1;
        expected_l1_file = "cnn_layer1_exp0.dat";
        expected_l1_compare_count = 1024;
        super.build_phase(phase);
    endfunction
endclass
