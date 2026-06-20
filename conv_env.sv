class conv_env extends uvm_env;
    conv_agent agent;
    conv_scoreboard sb;
    conv_coverage cov;
    conv_l0_mem_model l0_mem;
    `uvm_component_utils(conv_env);

    function new(string name = "conv_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = conv_agent::type_id::create("agent", this);
        sb = conv_scoreboard::type_id::create("sb", this);
        cov = conv_coverage::type_id::create("cov", this);
        l0_mem = conv_l0_mem_model::type_id::create("l0_mem", this);
        `uvm_info("CONV_ENV", "env built agent", UVM_LOW);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(sb.imp);
        agent.monitor.ap.connect(cov.analysis_export);
        agent.monitor.ap.connect(l0_mem.imp);
        `uvm_info("CONV_ENV", "env connect agent", UVM_LOW);
    endfunction
endclass
