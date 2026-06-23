class conv_reset_inflight_sequence extends conv_basic_sequence;
    `uvm_object_utils(conv_reset_inflight_sequence)

    function new(string name = "conv_reset_inflight_sequence");
        super.new(name);
    endfunction

    task body();
        `uvm_info("CONV_RESET_SEQ", "start reset-in-flight scenario", UVM_LOW)
        super.body();
    endtask
endclass
