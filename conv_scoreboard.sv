class conv_scoreboard extends uvm_component;
    `uvm_component_utils(conv_scoreboard);
    int observed_count = 0;
    int received_count = 0;
    int layer0_write_count = 0;
    int expected_ready_count = 3;
    int expected_l0_write_min = 0;
    int layer0_read_count = 0;
    int layer1_write_count = 0;
    int expected_l0_read_min = 0;
    int expected_l1_write_min = 0;
    uvm_analysis_imp #(conv_mem_wr_tr, conv_scoreboard) imp;

    function new(string name = "conv_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
        void'(uvm_config_db#(int)::get(this, "", "expected_ready_count", expected_ready_count));
        void'(uvm_config_db#(int)::get(this, "", "expected_l0_write_min", expected_l0_write_min));
        void'(uvm_config_db#(int)::get(this, "", "expected_l0_read_min", expected_l0_read_min));
        void'(uvm_config_db#(int)::get(this, "", "expected_l1_write_min", expected_l1_write_min));
    endfunction

    function void write(conv_mem_wr_tr tr);
        if (tr.write_seen) begin
            if (tr.is_layer0_write) begin
                layer0_write_count++;
                `uvm_info("CONV_SCOREBOARD",
                    $sformatf("layer0 write check passed count=%0d addr=%0d data=%0h",
                            layer0_write_count, tr.caddr_wr, tr.cdata_wr),
                    UVM_LOW)
            end
            if (tr.is_layer1_write) begin
                layer1_write_count++;
                `uvm_info("CONV_SCOREBOARD",
                    $sformatf("layer1 write check passed count=%0d addr=%0d data=%0h",
                            layer1_write_count, tr.caddr_wr, tr.cdata_wr),
                    UVM_LOW)
            end
            return;
        end

        if (tr.read_seen) begin
            if (tr.is_layer0_read) begin
                layer0_read_count++;
                `uvm_info("CONV_SCOREBOARD",
                    $sformatf("layer0 read check passed count=%0d addr=%0d",
                            layer0_read_count, tr.caddr_rd),
                    UVM_LOW)
            end
            return;
        end

        observed_count = observed_count + 1;
        if (!tr.ready_seen) begin
            `uvm_error("CONV_SCOREBOARD", "expected ready_seen transaction")
        end
        else begin
            received_count = received_count + 1;
            `uvm_info("CONV_SCOREBOARD", "ready transaction check passed", UVM_LOW)
        end
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (observed_count  != expected_ready_count) begin
            `uvm_error("CONV_SCOREBOARD",
                $sformatf("expected ready count=%0d actual=%0d",
                          expected_ready_count, observed_count ))
        end
        else begin
            `uvm_info("CONV_SCOREBOARD",
                $sformatf("received expected ready count=%0d", observed_count ),
                UVM_LOW)
        end
        if (layer0_write_count < expected_l0_write_min) begin
            `uvm_error("CONV_SCOREBOARD",
                $sformatf("expected layer0 write min=%0d actual=%0d",
                        expected_l0_write_min, layer0_write_count))
        end
        else begin
            `uvm_info("CONV_SCOREBOARD",
                $sformatf("observed expected layer0 write count=%0d",
                        layer0_write_count),
                UVM_LOW)
        end
        if (layer0_read_count < expected_l0_read_min) begin
            `uvm_error("CONV_SCOREBOARD",
                $sformatf("expected layer0 read min=%0d actual=%0d",
                        expected_l0_read_min, layer0_read_count))
        end
        else begin
            `uvm_info("CONV_SCOREBOARD",
                $sformatf("observed expected layer0 read count=%0d",
                        layer0_read_count),
                UVM_LOW)
        end

        if (layer1_write_count < expected_l1_write_min) begin
            `uvm_error("CONV_SCOREBOARD",
                $sformatf("expected layer1 write min=%0d actual=%0d",
                        expected_l1_write_min, layer1_write_count))
        end
        else begin
            `uvm_info("CONV_SCOREBOARD",
                $sformatf("observed expected layer1 write count=%0d",
                        layer1_write_count),
                UVM_LOW)
        end
    endfunction
endclass
