class conv_coverage extends uvm_subscriber #(conv_mem_wr_tr);
    `uvm_component_utils(conv_coverage);
    int ready_seen_cnt = 0;

    function new(string name = "conv_coverage", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void write(conv_mem_wr_tr t);
        if (t.ready_seen) begin
            ready_seen_cnt = ready_seen_cnt + 1;
             `uvm_info("CONV_COVERAGE", "sampled ready transaction", UVM_LOW)
        end
    endfunction
endclass
