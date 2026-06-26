`timescale 1ns/1ps

module conv_sva(
    input logic        clk,
    input logic        reset,
    input logic        busy,
    input logic        ready,
    input logic        cwr,
    input logic        crd,
    input logic [2:0]  csel,
    input logic [11:0] caddr_wr
);
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    initial begin
        `uvm_info("CONV_SVA", "sva protocol checker enabled", UVM_LOW)
    end

    // Skeleton only. Fault-facing SVA properties are enabled in the next step.

endmodule
