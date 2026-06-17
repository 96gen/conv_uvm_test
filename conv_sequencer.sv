class conv_sequencer extends uvm_sequencer #(conv_seq_item);

   `uvm_component_utils(conv_sequencer)
  conv_sequencer seqr;
  conv_basic_sequence seq;

  function new(string name = "conv_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass