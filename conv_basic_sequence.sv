class conv_basic_sequence extends uvm_sequence #(conv_seq_item);
    `uvm_object_utils(conv_basic_sequence)
    conv_seq_item req;

    function new(string name = "conv_basic_sequence");
        super.new(name);
    endfunction

        task body();
            req = conv_seq_item::type_id::create("req");
            //start_item(req);
            //finish_item(req);
            `uvm_info("CONV_SEQ", "basic sequence generated item", UVM_LOW);
        endtask
endclass
