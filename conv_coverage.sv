class conv_coverage extends uvm_subscriber #(conv_mem_wr_tr);
    `uvm_component_utils(conv_coverage);
    int ready_seen_cnt = 0;
    int reset_seen_count = 0;
    int layer0_write_count = 0;
    int layer0_read_count = 0;
    int layer1_write_count = 0;
    bit cov_ready_seen;
    bit cov_reset_seen;
    bit cov_write_seen;
    bit cov_read_seen;
    bit cov_layer0_write;
    bit cov_layer1_write;
    bit cov_layer0_read;
    bit [11:0] cov_addr;
    int addr_low_bucket_count = 0;
    int addr_mid_bucket_count = 0;
    int addr_high_bucket_count = 0;
    int fault_class_id = 0;
    string fault_class_name = "none";
    bit fault_class_sampled = 0;
    int fault_class_bin_count [0:8];

`ifdef CONV_ENABLE_COVERGROUPS
    covergroup conv_bus_cg;
        option.per_instance = 1;
        ready_cp: coverpoint cov_ready_seen {
            bins ready = {1};
        }
        reset_cp: coverpoint cov_reset_seen {
            bins reset = {1};
        }
        write_cp: coverpoint cov_write_seen {
            bins write = {1};
        }
        read_cp: coverpoint cov_read_seen {
            bins read = {1};
        }
        layer_cp: coverpoint {cov_layer0_write, cov_layer1_write, cov_layer0_read} {
            bins l0_write = {3'b100};
            bins l1_write = {3'b010};
            bins l0_read = {3'b001};
        }
        addr_bucket_cp: coverpoint cov_addr iff (cov_write_seen || cov_read_seen) {
            bins low = {[12'd0:12'd63]};
            bins mid = {[12'd64:12'd1023]};
            bins high = {[12'd1024:12'd4095]};
        }
        fault_class_cp: coverpoint fault_class_id {
            bins none = {0};
            bins l0_data = {1};
            bins l1_data = {2};
            bins illegal_csel = {3};
            bins missing_l0 = {4};
            bins duplicate_l1 = {5};
            bins l1_addr_oob = {6};
            bins reset_protocol = {7};
            bins ready_busy_timeout = {8};
        }
    endgroup
`endif

    function new(string name = "conv_coverage", uvm_component parent = null);
        super.new(name, parent);
`ifdef CONV_ENABLE_COVERGROUPS
        conv_bus_cg = new();
`endif
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'($value$plusargs("CONV_FAULT_CLASS_ID=%d", fault_class_id));
        void'($value$plusargs("CONV_FAULT_CLASS_NAME=%s", fault_class_name));
    endfunction

    function void write(conv_mem_wr_tr t);
        cov_ready_seen = t.ready_seen;
        cov_reset_seen = t.reset_seen;
        cov_write_seen = t.write_seen;
        cov_read_seen = t.read_seen;
        cov_layer0_write = t.is_layer0_write;
        cov_layer1_write = t.is_layer1_write;
        cov_layer0_read = t.is_layer0_read;
        cov_addr = t.write_seen ? t.caddr_wr :
                   (t.read_seen ? t.caddr_rd : 12'd0);
`ifdef CONV_ENABLE_COVERGROUPS
        conv_bus_cg.sample();
`endif

        if (t.write_seen || t.read_seen) begin
            if (cov_addr <= 12'd63)
                addr_low_bucket_count++;
            else if (cov_addr <= 12'd1023)
                addr_mid_bucket_count++;
            else
                addr_high_bucket_count++;
        end

        if (fault_class_id > 0 && !fault_class_sampled) begin
            if (fault_class_id <= 8)
                fault_class_bin_count[fault_class_id]++;
            fault_class_sampled = 1'b1;
            `uvm_info("CONV_COVERAGE",
                $sformatf("fault_class=%s id=%0d covered",
                        fault_class_name, fault_class_id),
                UVM_LOW)
        end

        if (t.reset_seen) begin
            reset_seen_count++;
            `uvm_info("CONV_COVERAGE",
                $sformatf("sampled reset transaction count=%0d", reset_seen_count),
                UVM_LOW)
        end
        if (t.ready_seen) begin
            ready_seen_cnt++;
            `uvm_info("CONV_COVERAGE",
                $sformatf("sampled ready transaction count=%0d", ready_seen_cnt),
                UVM_LOW)
        end
        if (t.write_seen && t.is_layer0_write) begin
            layer0_write_count++;
            `uvm_info("CONV_COVERAGE",
                $sformatf("sampled layer0 write count=%0d", layer0_write_count),
                UVM_LOW)
        end
        if (t.write_seen && t.is_layer1_write) begin
            layer1_write_count++;
            `uvm_info("CONV_COVERAGE",
                $sformatf("sampled layer1 write count=%0d", layer1_write_count),
                UVM_LOW)
        end
        if (t.read_seen && t.is_layer0_read) begin
            layer0_read_count++;
            `uvm_info("CONV_COVERAGE",
                $sformatf("sampled layer0 read count=%0d", layer0_read_count),
                UVM_LOW)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("CONV_COVERAGE",
            $sformatf("ready_seen_count=%0d", ready_seen_cnt),
            UVM_LOW)
        `uvm_info("CONV_COVERAGE",
            $sformatf("reset_seen_count=%0d", reset_seen_count),
            UVM_LOW)
        `uvm_info("CONV_COVERAGE",
            $sformatf("layer0_write_count=%0d", layer0_write_count),
            UVM_LOW)
        `uvm_info("CONV_COVERAGE",
            $sformatf("layer0_read_count=%0d", layer0_read_count),
            UVM_LOW)
        `uvm_info("CONV_COVERAGE",
            $sformatf("layer1_write_count=%0d", layer1_write_count),
            UVM_LOW)
        `uvm_info("CONV_COVERAGE",
            $sformatf("addr_bucket_counts low=%0d mid=%0d high=%0d",
                    addr_low_bucket_count, addr_mid_bucket_count,
                    addr_high_bucket_count),
            UVM_LOW)
        if (fault_class_id > 0) begin
            `uvm_info("CONV_COVERAGE",
                $sformatf("fault_class=%s id=%0d samples=%0d",
                        fault_class_name, fault_class_id,
                        (fault_class_id <= 8) ? fault_class_bin_count[fault_class_id] : 0),
                UVM_LOW)
        end
`ifdef CONV_ENABLE_COVERGROUPS
        `uvm_info("CONV_COVERAGE",
            $sformatf("bus covergroup coverage=%0.2f", conv_bus_cg.get_inst_coverage()),
            UVM_LOW)
`else
        `uvm_info("CONV_COVERAGE",
            "bus covergroup coverage disabled; using counter fallback",
            UVM_LOW)
`endif
    endfunction
endclass
