`timescale 1ns/1ps

module conv_assertions(
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

    bit reset_busy_reported;
    bit reset_cwr_reported;
    bit reset_crd_reported;

    initial begin
        `uvm_info("CONV_ASSERTIONS", "protocol checker enabled", UVM_LOW)
    end

    always @(negedge clk) begin
        if (reset) begin
            if (busy && !reset_busy_reported) begin
                reset_busy_reported = 1'b1;
                `uvm_error("RESET_BUSY", "busy must be low while reset is asserted")
            end

            if (cwr && !reset_cwr_reported) begin
                reset_cwr_reported = 1'b1;
                `uvm_error("RESET_CWR", "cwr must be low while reset is asserted")
            end

            if (crd && !reset_crd_reported) begin
                reset_crd_reported = 1'b1;
                `uvm_error("RESET_CRD", "crd must be low while reset is asserted")
            end
        end
        else begin
            reset_busy_reported = 1'b0;
            reset_cwr_reported = 1'b0;
            reset_crd_reported = 1'b0;

            if (cwr && crd) begin
                `uvm_error("CWR_CRD_CONFLICT", "cwr and crd must not be asserted together")
            end

            if (cwr && (csel != 3'b001) && (csel != 3'b011)) begin
                `uvm_error("CWR_ILLEGAL_CSEL",
                    $sformatf("cwr requires csel 001 or 011, got %03b", csel))
            end

            if (crd && (csel != 3'b001)) begin
                `uvm_error("CRD_ILLEGAL_CSEL",
                    $sformatf("crd requires csel 001, got %03b", csel))
            end

            if (cwr && (csel == 3'b011) && (caddr_wr >= 12'd1024)) begin
                `uvm_error("L1_ADDR_OOB",
                    $sformatf("layer1 write address out of range=%0d", caddr_wr))
            end

            if (ready && busy) begin
                `uvm_error("READY_WHILE_BUSY", "ready must not be asserted while busy is high")
            end
        end
    end
endmodule
