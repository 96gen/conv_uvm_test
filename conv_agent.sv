class conv_agent extends uvm_agent;
    conv_sequencer seqr;
    conv_driver driver;
    conv_monitor monitor;
    `uvm_component_utils(conv_agent);

    function new(string name = "conv_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seqr = conv_sequencer::type_id::create("seqr", this);
        driver = conv_driver::type_id::create("driver", this);
        monitor = conv_monitor::type_id::create("monitor", this);
        `uvm_info("CONV_AGENT", "agent built sequencer", UVM_LOW)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(seqr.seq_item_export);
        `uvm_info("CONV_AGENT", "enter connect_phase", UVM_LOW)
    endfunction
endclass
