class conv_l0_mem_model extends uvm_component;
    `uvm_component_utils(conv_l0_mem_model)

    virtual CONV_IF vif;
    uvm_analysis_imp #(conv_mem_wr_tr, conv_l0_mem_model) imp;
    logic [19:0] l0_mem [0:4095];

    function new(string name = "conv_l0_mem_model", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
        if (!uvm_config_db#(virtual CONV_IF)::get(this, "", "vif", vif))
            `uvm_fatal("CONV_L0_MEM", "cannot get vif")
    endfunction

    function void write(conv_mem_wr_tr tr);
        if (tr.write_seen && tr.is_layer0_write) begin
            l0_mem[tr.caddr_wr] = tr.cdata_wr;
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            if (vif.crd && vif.csel == 3'b001) begin
                vif.cdata_rd <= l0_mem[vif.caddr_rd];
                `uvm_info("CONV_L0_MEM",
                    $sformatf("served layer0 read addr=%0d data=%0h",
                              vif.caddr_rd, l0_mem[vif.caddr_rd]),
                    UVM_LOW)
            end
            else begin
                vif.cdata_rd <= 20'd0;
            end
        end
    endtask
endclass