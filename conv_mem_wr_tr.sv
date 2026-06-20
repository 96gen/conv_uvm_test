class conv_mem_wr_tr extends uvm_sequence_item;
  bit ready_seen;
  bit write_seen;
  logic [2:0] csel;
  logic [11:0] caddr_wr;
  logic [19:0] cdata_wr;
  bit is_layer0_write;

  `uvm_object_utils(conv_mem_wr_tr)

  function new(string name = "conv_mem_wr_tr");
    super.new(name);
  endfunction
endclass