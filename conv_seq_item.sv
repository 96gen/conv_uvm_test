class conv_seq_item extends uvm_sequence_item;
    int unsigned reset_cycles;
    int unsigned ready_delay_cycles;
    int unsigned ready_pulse_cycles;
    bit expect_ready_seen;
    `uvm_object_utils(conv_seq_item)

    function new(string name = "conv_seq_item");
        super.new(name);
    endfunction

endclass
