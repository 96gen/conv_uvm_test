class conv_reset_inflight_test extends conv_test;
    `uvm_component_utils(conv_reset_inflight_test)
    conv_reset_inflight_sequence reset_seq;

    function new(string name = "conv_reset_inflight_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        item_count = 1;
        expected_ready_count = 2;
        img_file = "cnn_sti.dat";
        dat_sample_words = 4;
        drive_dut_input = 1;
        dut_drive_cycles = 63000;
        dut_drive_log_stride = 512;
        expected_l0_write_min = 4096;
        expected_l0_read_min = 4096;
        expected_l1_write_min = 1024;
        check_l1_expected = 1;
        expected_l1_file = "cnn_layer1_exp0.dat";
        expected_l1_compare_count = 1024;
        reset_inflight = 1;
        reset_at_cycle = 256;
        reset_hold_cycles = 6;
        rerun_after_reset = 1;
        super.build_phase(phase);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        reset_seq = conv_reset_inflight_sequence::type_id::create("reset_seq");
        reset_seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass
