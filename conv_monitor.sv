class conv_monitor extends uvm_monitor;
    virtual CONV_IF vif;
    `uvm_component_utils(conv_monitor);
    uvm_analysis_port #(conv_mem_wr_tr) ap;
    bit inject_bad_ready_tr;

    function new(string name = "conv_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual CONV_IF)::get(this, "", "vif", vif)) begin
            `uvm_fatal("CONV_MONITOR", "cannot get vif")
        end
        `uvm_info("CONV_MONITOR", "got virtual interface", UVM_LOW)
        ap = new("ap", this);
        void'(uvm_config_db#(bit)::get(this, "", "inject_bad_ready_tr", inject_bad_ready_tr));
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            @(posedge vif.clk);
            if(vif.ready) begin
                conv_mem_wr_tr tr;
                tr = conv_mem_wr_tr::type_id::create("tr");
                tr.ready_seen = inject_bad_ready_tr ? 1'b0 : 1'b1;
                ap.write(tr);
                `uvm_info("CONV_MONITOR", "write transaction", UVM_LOW)
            end
        end
    endtask
endclass
