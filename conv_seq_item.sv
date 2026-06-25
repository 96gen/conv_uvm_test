class conv_seq_item extends uvm_sequence_item;
    int unsigned reset_cycles;
    int unsigned ready_delay_cycles;
    int unsigned ready_pulse_cycles;
    bit expect_ready_seen;
    string img_file;
    int unsigned dat_sample_words;
    bit drive_dut_input;
    int unsigned dut_drive_cycles;
    int unsigned dut_drive_log_stride;
    bit reset_inflight;
    int unsigned reset_at_cycle;
    int unsigned reset_hold_cycles;
    bit rerun_after_reset;
    bit inject_ready_while_busy;
    `uvm_object_utils(conv_seq_item)

    function new(string name = "conv_seq_item");
        super.new(name);
    endfunction

endclass
