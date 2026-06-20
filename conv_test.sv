class conv_test extends uvm_test;
    virtual CONV_IF vif;
    conv_env env;
    conv_basic_sequence seq;
    int item_count = 3;
    int expected_ready_count = 3;
    string img_file;
    int unsigned dat_sample_words;
    bit drive_dut_input = 0;
    int unsigned dut_drive_cycles = 0;
    int expected_l0_write_min = 0;
    int expected_l0_read_min = 0;
    int expected_l1_write_min = 0;
    int unsigned dut_drive_log_stride = 1;
    `uvm_component_utils(conv_test);

    function new(string name = "conv_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual CONV_IF)::get(this, "", "vif", vif)) begin
            `uvm_fatal("CONV_TEST", "cannot get vif");
        end
        `uvm_info("CONV_TEST", "connect to vif", UVM_LOW);
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
        seq = conv_basic_sequence::type_id::create("seq");
        env = conv_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass
