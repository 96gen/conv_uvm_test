interface CONV_IF(input         clk);
    logic         reset;
    logic    busy;
    logic         ready;
    logic [11:0] iaddr;
    logic  [19:0] idata;
    logic    cwr;
    logic [11:0] caddr_wr;
    logic [19:0] cdata_wr;
    logic    crd;
    logic [11:0] caddr_rd;
    logic  [19:0] cdata_rd;
    logic [2:0]  csel;
endinterface
