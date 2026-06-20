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
            if (req.drive_dut_input) begin
                drive_dut_input_from_dat(req);
            end
            else if (req.img_file != "") begin
                read_dat_sample(req);
            end
            seq_item_port.item_done();
            `uvm_info("CONV_DRIVER", "item done", UVM_LOW);
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

    task drive_dut_input_from_dat(conv_seq_item req);
        int fd;
        int code;
        int unsigned word;
        int unsigned img_mem [0:4095];
        string line;

        fd = $fopen(req.img_file, "r");
        if (fd == 0) begin
            `uvm_error("CONV_DRIVER", $sformatf("cannot open dat file %s", req.img_file))
            return;
        end

        `uvm_info("CONV_DRIVER", $sformatf("opened dat file %s", req.img_file), UVM_LOW)

        for (int i = 0; i < 4096; i++) begin
            if (!$fgets(line, fd)) begin
                `uvm_error("CONV_DRIVER", $sformatf("dat file ended early at sample %0d", i))
                break;
            end

            code = $sscanf(line, "%h", word);
            if (code != 1) begin
                `uvm_error("CONV_DRIVER", $sformatf("cannot parse dat line %0d: %s", i, line))
            end
            else begin
                img_mem[i] = word[19:0];
                if (i < req.dat_sample_words) begin
                    `uvm_info("CONV_DRIVER", $sformatf("read dat sample[%0d]=%0h", i, img_mem[i]), UVM_LOW)
                end
            end
        end

        $fclose(fd);

        for (int cycle = 0; cycle < req.dut_drive_cycles; cycle++) begin
            @(posedge vif.clk);
            vif.idata <= img_mem[vif.iaddr];
            vif.cdata_rd <= 20'd0;
            `uvm_info("CONV_DRIVER", $sformatf("drive idata addr=%0d data=%0h", vif.iaddr, img_mem[vif.iaddr]), UVM_LOW)
        end
    endtask
endclass
