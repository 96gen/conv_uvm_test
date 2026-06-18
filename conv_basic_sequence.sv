class conv_basic_sequence extends uvm_sequence #(conv_seq_item);
    `uvm_object_utils(conv_basic_sequence)
    conv_seq_item req;

    function new(string name = "conv_basic_sequence");
        super.new(name);
    endfunction

        task body();
            req = conv_seq_item::type_id::create("req");
            start_item(req);
            req.reset_cycles = 10;
            req.ready_delay_cycles = 0;
            req.ready_pulse_cycles = 1;
            req.expect_ready_seen = 1;
            finish_item(req);
            `uvm_info("CONV_SEQ", "drive item reset_cycles=10 ready_delay_cycles=0 ready_pulse_cycles=1", UVM_LOW);
        endtask
endclass
