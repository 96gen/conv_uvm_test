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
            `uvm_info("CONV_DRIVER",
                $sformatf("drive item reset_cycles=%0d ready_delay_cycles=%0d ready_pulse_cycles=%0d",
                req.reset_cycles, req.ready_delay_cycles, req.ready_pulse_cycles),
            UVM_LOW)
            basic_phase(req);
            seq_item_port.item_done();
            `uvm_info("CONV_DRIVER", "item done", UVM_LOW);
            if(req.img_file != "") begin
                read_dat_sample(req);
            end
        end 
    endtask

    task basic_phase(conv_seq_item req);
        vif.reset <= 1'b1;
        repeat (req.reset_cycles) @(posedge vif.clk);
        vif.reset <= 1'b0;
        `uvm_info("CONV_DRIVER", "reset done", UVM_LOW);
        repeat (req.ready_delay_cycles) @(posedge vif.clk);
        vif.ready <= 1'b1;
        repeat (req.ready_pulse_cycles) @(posedge vif.clk);
        vif.ready <= 1'b0;
        `uvm_info("CONV_DRIVER", "ready pulse done", UVM_LOW);
    endtask

    task read_dat_sample(conv_seq_item req);
        int fd;
        int code;
        int unsigned word;
        string line;

        fd = $fopen(req.img_file, "r");
        if (fd == 0) begin
            `uvm_error("CONV_DRIVER", $sformatf("cannot open dat file %s", req.img_file))
            return;
        end

        `uvm_info("CONV_DRIVER", $sformatf("opened dat file %s", req.img_file), UVM_LOW)

        for (int i = 0; i < req.dat_sample_words; i++) begin
            if (!$fgets(line, fd)) begin
                `uvm_error("CONV_DRIVER", $sformatf("dat file ended early at sample %0d", i))
                break;
            end

            code = $sscanf(line, "%h", word);
            if (code != 1) begin
                `uvm_error("CONV_DRIVER", $sformatf("cannot parse dat line %0d: %s", i, line))
            end
            else begin
                `uvm_info("CONV_DRIVER", $sformatf("read dat sample[%0d]=%0h", i, word), UVM_LOW)
            end
        end

        $fclose(fd);
    endtask
endclass
