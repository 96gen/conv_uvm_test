class conv_driver extends uvm_driver #(conv_seq_item);
    virtual CONV_IF vif;
    `uvm_component_utils(conv_driver);

    function new(string name = "conv_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual CONV_IF)::get(this, "", "vif", vif)) begin
            `uvm_fatal("CONV_DRIVER", "cannot get vif")
        end
        `uvm_info("CONV_DRIVER", "got virtual interface", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        conv_seq_item req;
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("CONV_DRIVER", "get seq_item", UVM_LOW);
            basic_phase();
            seq_item_port.item_done();
            `uvm_info("CONV_DRIVER", "item done", UVM_LOW);
        end 
    endtask

    task basic_phase();
        vif.reset <= 1'b1;
        repeat (10) @(posedge vif.clk);
        vif.reset <= 1'b0;
        `uvm_info("CONV_DRIVER", "reset done", UVM_LOW);
        vif.ready <= 1'b1;
        @(posedge vif.clk);
        vif.ready <= 1'b0;
        `uvm_info("CONV_DRIVER", "ready pulse done", UVM_LOW);
    endtask
endclass
