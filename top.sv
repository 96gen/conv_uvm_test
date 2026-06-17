`timescale 1ns/10ps
import uvm_pkg::*;
import conv_pkg::*;
module top();
    bit clk = 1'b0;
    always #5 clk = ~clk;
    CONV_IF vif(clk);
    CONV dut(
        clk,
        vif.reset,
        vif.busy,
        vif.ready,
        vif.iaddr,
        vif.idata,
        vif.cwr,
        vif.caddr_wr,
        vif.cdata_wr,
        vif.crd,
        vif.caddr_rd,
        vif.cdata_rd,
        vif.csel
    );
    initial begin
        uvm_config_db#(virtual CONV_IF)::set(null, "*", "vif", vif);
        run_test("conv_test");
    end
endmodule
