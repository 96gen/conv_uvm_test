class conv_basic_sequence extends uvm_sequence #(conv_seq_item);
    `uvm_object_utils(conv_basic_sequence)
    conv_seq_item req;
    int item_count = 3;
    string img_file;
    int unsigned dat_sample_words;
    bit drive_dut_input;
    int unsigned dut_drive_cycles;
    int unsigned dut_drive_log_stride = 1;
    bit reset_inflight;
    int unsigned reset_at_cycle;
    int unsigned reset_hold_cycles;
    bit rerun_after_reset;
    bit inject_ready_while_busy;

    function new(string name = "conv_basic_sequence");
        super.new(name);
    endfunction

        task body();
            void'(uvm_config_db#(int)::get(get_sequencer(), "", "item_count", item_count));
            void'(uvm_config_db#(string)::get(get_sequencer(), "", "img_file", img_file));
            void'(uvm_config_db#(int unsigned)::get(get_sequencer(), "", "dat_sample_words", dat_sample_words));
            void'(uvm_config_db#(bit)::get(get_sequencer(), "", "drive_dut_input", drive_dut_input));
            void'(uvm_config_db#(int unsigned)::get(get_sequencer(), "", "dut_drive_cycles", dut_drive_cycles));
            void'(uvm_config_db#(int unsigned)::get(get_sequencer(), "", "dut_drive_log_stride", dut_drive_log_stride));
            void'(uvm_config_db#(bit)::get(get_sequencer(), "", "reset_inflight", reset_inflight));
            void'(uvm_config_db#(int unsigned)::get(get_sequencer(), "", "reset_at_cycle", reset_at_cycle));
            void'(uvm_config_db#(int unsigned)::get(get_sequencer(), "", "reset_hold_cycles", reset_hold_cycles));
            void'(uvm_config_db#(bit)::get(get_sequencer(), "", "rerun_after_reset", rerun_after_reset));
            void'(uvm_config_db#(bit)::get(get_sequencer(), "", "inject_ready_while_busy", inject_ready_while_busy));
            for (int i = 0; i < item_count; i++) begin
                send_item(10 + i*10, i, 1);
            end
        endtask

        task send_item(
            int unsigned reset_cycles,
            int unsigned ready_delay_cycles,
            int unsigned ready_pulse_cycles
        );
            req = conv_seq_item::type_id::create("req");
            start_item(req);
            req.reset_cycles = reset_cycles;
            req.ready_delay_cycles = ready_delay_cycles;
            req.ready_pulse_cycles = ready_pulse_cycles;
            req.expect_ready_seen = 1;
            req.img_file = img_file;
            req.dat_sample_words = dat_sample_words;
            req.drive_dut_input = drive_dut_input;
            req.dut_drive_cycles = dut_drive_cycles;
            req.dut_drive_log_stride = dut_drive_log_stride;
            req.reset_inflight = reset_inflight;
            req.reset_at_cycle = reset_at_cycle;
            req.reset_hold_cycles = reset_hold_cycles;
            req.rerun_after_reset = rerun_after_reset;
            req.inject_ready_while_busy = inject_ready_while_busy;
            finish_item(req);

            `uvm_info("CONV_SEQ",
                $sformatf("drive item reset_cycles=%0d ready_delay_cycles=%0d ready_pulse_cycles=%0d",
                        reset_cycles, ready_delay_cycles, ready_pulse_cycles),
                UVM_LOW)
        endtask
endclass
