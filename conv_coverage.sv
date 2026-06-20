class conv_coverage extends uvm_subscriber #(conv_mem_wr_tr);
    `uvm_component_utils(conv_coverage);
    int ready_seen_cnt = 0;
    int layer0_write_count = 0;
    int layer0_read_count = 0;
    int layer1_write_count = 0;

    function new(string name = "conv_coverage", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void write(conv_mem_wr_tr t);
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
            $sformatf("layer0_write_count=%0d", layer0_write_count),
            UVM_LOW)
        `uvm_info("CONV_COVERAGE",
            $sformatf("layer0_read_count=%0d", layer0_read_count),
            UVM_LOW)
        `uvm_info("CONV_COVERAGE",
            $sformatf("layer1_write_count=%0d", layer1_write_count),
            UVM_LOW)
    endfunction
endclass
