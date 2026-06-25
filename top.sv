`timescale 1ns/10ps
import uvm_pkg::*;
import conv_pkg::*;
module top();
    bit clk = 1'b0;
    always #5 clk = ~clk;
    CONV_IF vif(clk);
    CONV dut(
        .clk      (clk),
        .reset    (vif.reset),
        .busy     (vif.busy),
        .ready    (vif.ready),
        .iaddr    (vif.iaddr),
        .idata    (vif.idata),
        .cwr      (vif.cwr),
        .caddr_wr (vif.caddr_wr),
        .cdata_wr (vif.cdata_wr),
        .crd      (vif.crd),
        .caddr_rd (vif.caddr_rd),
        .cdata_rd (vif.cdata_rd),
        .csel     (vif.csel)
    );
    conv_assertions protocol_checker(
        .clk   (clk),
        .reset (vif.reset),
        .busy  (vif.busy),
        .ready (vif.ready),
        .cwr   (vif.cwr),
        .crd   (vif.crd),
        .csel  (vif.csel)
    );
    initial begin
        uvm_config_db#(virtual CONV_IF)::set(null, "*", "vif", vif);
        run_test();
    end
endmodule
