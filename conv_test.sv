class conv_test extends uvm_test;
    virtual CONV_IF vif;
    conv_env env;
    conv_basic_sequence seq;
    int item_count = 3;
    int expected_ready_count = 3;
    string dataset_root;
    string img_file;
    int unsigned dat_sample_words;
    bit drive_dut_input = 0;
    int unsigned dut_drive_cycles = 0;
    int expected_l0_write_min = 0;
    int expected_l0_read_min = 0;
    int expected_l1_write_min = 0;
    int unsigned dut_drive_log_stride = 1;
    bit check_l0_expected = 0;
    string expected_l0_file;
    int expected_l0_compare_count = 0;
    bit check_l0_addr_map = 0;
    int expected_l0_addr_count = 0;
    bit check_l1_expected = 0;
    string expected_l1_file;
    int expected_l1_compare_count = 0;
    bit check_l1_addr_map = 0;
    int expected_l1_addr_count = 0;
    bit reset_inflight = 0;
    int unsigned reset_at_cycle = 0;
    int unsigned reset_hold_cycles = 0;
    bit rerun_after_reset = 0;
    bit inject_ready_while_busy = 0;
    `uvm_component_utils(conv_test);

    function new(string name = "conv_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void apply_dataset_root();
        void'($value$plusargs("CONV_DATASET_ROOT=%s", dataset_root));
        if (dataset_root != "") begin
            if (img_file != "")
                img_file = {dataset_root, "/", img_file};
            if (expected_l0_file != "")
                expected_l0_file = {dataset_root, "/", expected_l0_file};
            if (expected_l1_file != "")
                expected_l1_file = {dataset_root, "/", expected_l1_file};
            `uvm_info("CONV_TEST",
                $sformatf("dataset root=%s", dataset_root),
                UVM_LOW)
        end
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual CONV_IF)::get(this, "", "vif", vif)) begin
            `uvm_fatal("CONV_TEST", "cannot get vif");
        end
        `uvm_info("CONV_TEST", "connect to vif", UVM_LOW);
        apply_dataset_root();
        uvm_config_db#(int)::set(this, "*", "item_count", item_count);
        uvm_config_db#(int)::set(this, "*", "expected_ready_count", expected_ready_count);
        uvm_config_db#(string)::set(this, "*", "img_file", img_file);
        uvm_config_db#(int unsigned)::set(this, "*", "dat_sample_words", dat_sample_words);
        uvm_config_db#(bit)::set(this, "*", "drive_dut_input", drive_dut_input);
        uvm_config_db#(int unsigned)::set(this, "*", "dut_drive_cycles", dut_drive_cycles);
        uvm_config_db#(int)::set(this, "*", "expected_l0_write_min", expected_l0_write_min);
        uvm_config_db#(int)::set(this, "*", "expected_l0_read_min", expected_l0_read_min);
        uvm_config_db#(int)::set(this, "*", "expected_l1_write_min", expected_l1_write_min);
        uvm_config_db#(int unsigned)::set(this, "*", "dut_drive_log_stride", dut_drive_log_stride);
        uvm_config_db#(bit)::set(this, "*", "check_l0_expected", check_l0_expected);
        uvm_config_db#(string)::set(this, "*", "expected_l0_file", expected_l0_file);
        uvm_config_db#(int)::set(this, "*", "expected_l0_compare_count", expected_l0_compare_count);
        uvm_config_db#(bit)::set(this, "*", "check_l0_addr_map", check_l0_addr_map);
        uvm_config_db#(int)::set(this, "*", "expected_l0_addr_count", expected_l0_addr_count);
        uvm_config_db#(bit)::set(this, "*", "check_l1_expected", check_l1_expected);
        uvm_config_db#(string)::set(this, "*", "expected_l1_file", expected_l1_file);
        uvm_config_db#(int)::set(this, "*", "expected_l1_compare_count", expected_l1_compare_count);
        uvm_config_db#(bit)::set(this, "*", "check_l1_addr_map", check_l1_addr_map);
        uvm_config_db#(int)::set(this, "*", "expected_l1_addr_count", expected_l1_addr_count);
        uvm_config_db#(bit)::set(this, "*", "reset_inflight", reset_inflight);
        uvm_config_db#(int unsigned)::set(this, "*", "reset_at_cycle", reset_at_cycle);
        uvm_config_db#(int unsigned)::set(this, "*", "reset_hold_cycles", reset_hold_cycles);
        uvm_config_db#(bit)::set(this, "*", "rerun_after_reset", rerun_after_reset);
        uvm_config_db#(bit)::set(this, "*", "inject_ready_while_busy", inject_ready_while_busy);
        seq = conv_basic_sequence::type_id::create("seq");
        env = conv_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass
