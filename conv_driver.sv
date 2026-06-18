class conv_driver extends uvm_driver #(conv_seq_item);
    `uvm_component_utils(conv_driver);

    function new(string name = "conv_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        conv_seq_item req;
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("CONV_DRIVER", "get seq_item", UVM_LOW)
            seq_item_port.item_done();
            `uvm_info("CONV_DRIVER", "item done", UVM_LOW)
        end 
    endtask
endclass
