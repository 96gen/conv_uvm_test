class conv_env extends uvm_env;
    conv_agent agent;
    `uvm_component_utils(conv_env);

    function new(string name = "conv_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = conv_agent::type_id::create("agent", this);
        `uvm_info("CONV_ENV", "env built agent", UVM_LOW);
    endfunction
endclass
