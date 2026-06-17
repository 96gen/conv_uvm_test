class conv_agent extends uvm_agent;
    conv_sequencer seqr;
    `uvm_component_utils(conv_agent);

    function new(string name = "conv_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = conv_sequencer::type_id::create("seqr", this);
        `uvm_info("CONV_AGENT", "agent built sequencer", UVM_LOW)
    endfunction
endclass
