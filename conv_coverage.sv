class conv_coverage extends uvm_subscriber #(conv_mem_wr_tr);
    `uvm_component_utils(conv_coverage);
    int ready_seen_cnt = 0;

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
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("CONV_COVERAGE",
            $sformatf("ready_seen_count=%0d", ready_seen_cnt),
            UVM_LOW)
    endfunction
endclass
