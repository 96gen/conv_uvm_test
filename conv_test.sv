class conv_test extends uvm_test;
    virtual CONV_IF vif;
    conv_env env;
    conv_basic_sequence seq;
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
        seq = conv_basic_sequence::type_id::create("seq");
        env = conv_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agent.seqr);
        phase.drop_objection(this);
    endtask
endclass
