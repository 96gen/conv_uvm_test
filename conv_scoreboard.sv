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
    bit check_l0_expected = 0;
    string expected_l0_file;
    int expected_l0_compare_count = 0;
    logic [19:0] l0_expected [0:4095];
    int l0_expected_pass_count = 0;
    int l0_expected_mismatch_count = 0;
    bit check_l1_expected = 0;
    string expected_l1_file;
    int expected_l1_compare_count = 0;
    logic [19:0] l1_expected [0:1023];
    int l1_expected_pass_count = 0;
    int l1_expected_mismatch_count = 0;
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
        void'(uvm_config_db#(bit)::get(this, "", "check_l0_expected", check_l0_expected));
        void'(uvm_config_db#(string)::get(this, "", "expected_l0_file", expected_l0_file));
        void'(uvm_config_db#(int)::get(this, "", "expected_l0_compare_count", expected_l0_compare_count));
        void'(uvm_config_db#(bit)::get(this, "", "check_l1_expected", check_l1_expected));
        void'(uvm_config_db#(string)::get(this, "", "expected_l1_file", expected_l1_file));
        void'(uvm_config_db#(int)::get(this, "", "expected_l1_compare_count", expected_l1_compare_count));

        if (check_l0_expected) begin
            load_l0_expected();
        end
        if (check_l1_expected) begin
            load_l1_expected();
        end
    endfunction

    function void write(conv_mem_wr_tr tr);
        if (tr.write_seen) begin
            if (tr.is_layer0_write) begin
                layer0_write_count++;
                `uvm_info("CONV_SCOREBOARD",
                    $sformatf("layer0 write check passed count=%0d addr=%0d data=%0h",
                            layer0_write_count, tr.caddr_wr, tr.cdata_wr),
                    UVM_LOW)
                if (check_l0_expected && tr.caddr_wr < expected_l0_compare_count) begin
                    if (tr.cdata_wr !== l0_expected[tr.caddr_wr]) begin
                        l0_expected_mismatch_count++;
                        `uvm_error("CONV_SCOREBOARD",
                            $sformatf("layer0 expected mismatch addr=%0d exp=%0h got=%0h",
                                    tr.caddr_wr, l0_expected[tr.caddr_wr], tr.cdata_wr))
                    end
                    else begin
                        l0_expected_pass_count++;
                    end
                end
            end
            if (tr.is_layer1_write) begin
                layer1_write_count++;
                `uvm_info("CONV_SCOREBOARD",
                    $sformatf("layer1 write check passed count=%0d addr=%0d data=%0h",
                            layer1_write_count, tr.caddr_wr, tr.cdata_wr),
                    UVM_LOW)
                if (check_l1_expected && tr.caddr_wr < expected_l1_compare_count) begin
                    if (tr.cdata_wr !== l1_expected[tr.caddr_wr]) begin
                        l1_expected_mismatch_count++;
                        `uvm_error("CONV_SCOREBOARD",
                            $sformatf("layer1 expected mismatch addr=%0d exp=%0h got=%0h",
                                    tr.caddr_wr, l1_expected[tr.caddr_wr], tr.cdata_wr))
                    end
                    else begin
                        l1_expected_pass_count++;
                    end
                end
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

        if (check_l0_expected) begin
            if (l0_expected_mismatch_count != 0 || l0_expected_pass_count < expected_l0_compare_count) begin
                `uvm_error("CONV_SCOREBOARD",
                    $sformatf("layer0 expected compare failed pass=%0d mismatch=%0d expected=%0d",
                            l0_expected_pass_count, l0_expected_mismatch_count, expected_l0_compare_count))
            end
            else begin
                `uvm_info("CONV_SCOREBOARD",
                    $sformatf("layer0 expected compare passed count=%0d", l0_expected_pass_count),
                    UVM_LOW)
            end
        end

        if (check_l1_expected) begin
            if (l1_expected_mismatch_count != 0 || l1_expected_pass_count < expected_l1_compare_count) begin
                `uvm_error("CONV_SCOREBOARD",
                    $sformatf("layer1 expected compare failed pass=%0d mismatch=%0d expected=%0d",
                            l1_expected_pass_count, l1_expected_mismatch_count, expected_l1_compare_count))
            end
            else begin
                `uvm_info("CONV_SCOREBOARD",
                    $sformatf("layer1 expected compare passed count=%0d", l1_expected_pass_count),
                    UVM_LOW)
            end
        end
    endfunction

    function void load_l0_expected();
        int fd;
        int code;
        int unsigned word;
        string line;

        fd = $fopen(expected_l0_file, "r");
        if (fd == 0) begin
            `uvm_error("CONV_SCOREBOARD", $sformatf("cannot open layer0 expected file %s", expected_l0_file))
            return;
        end

        for (int i = 0; i < expected_l0_compare_count; i++) begin
            if (!$fgets(line, fd)) begin
                `uvm_error("CONV_SCOREBOARD", $sformatf("layer0 expected ended early at %0d", i))
                break;
            end

            code = $sscanf(line, "%h", word);
            if (code != 1)
                `uvm_error("CONV_SCOREBOARD", $sformatf("cannot parse layer0 expected line %0d", i))
            else
                l0_expected[i] = word[19:0];
        end

        $fclose(fd);
        `uvm_info("CONV_SCOREBOARD",
            $sformatf("loaded layer0 expected file %s count=%0d",
                    expected_l0_file, expected_l0_compare_count),
            UVM_LOW)
    endfunction

    function void load_l1_expected();
        int fd;
        int code;
        int unsigned word;
        string line;

        fd = $fopen(expected_l1_file, "r");
        if (fd == 0) begin
            `uvm_error("CONV_SCOREBOARD", $sformatf("cannot open layer1 expected file %s", expected_l1_file))
            return;
        end

        for (int i = 0; i < expected_l1_compare_count; i++) begin
            if (!$fgets(line, fd)) begin
                `uvm_error("CONV_SCOREBOARD", $sformatf("layer1 expected ended early at %0d", i))
                break;
            end

            code = $sscanf(line, "%h", word);
            if (code != 1)
                `uvm_error("CONV_SCOREBOARD", $sformatf("cannot parse layer1 expected line %0d", i))
            else
                l1_expected[i] = word[19:0];
        end

        $fclose(fd);
        `uvm_info("CONV_SCOREBOARD",
            $sformatf("loaded layer1 expected file %s count=%0d",
                    expected_l1_file, expected_l1_compare_count),
            UVM_LOW)
    endfunction
endclass
