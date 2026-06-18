class conv_mem_wr_tr extends uvm_sequence_item;
  bit ready_seen;

  `uvm_object_utils(conv_mem_wr_tr)

  function new(string name = "conv_mem_wr_tr");
    super.new(name);
  endfunction
endclass