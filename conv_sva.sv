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

    bit reset_busy_reported;
    bit reset_cwr_reported;
    bit reset_crd_reported;
    bit ready_busy_pending;
    int unsigned ready_busy_wait_cycles;
    localparam int READY_BUSY_TIMEOUT_CYCLES = 8;

    initial begin
        `uvm_info("CONV_SVA", "sva protocol checker enabled", UVM_LOW)
    end

    function bit has_unknown_inputs();
        has_unknown_inputs = ((^{reset, busy, ready, cwr, crd, csel, caddr_wr}) === 1'bx);
    endfunction

    always @(negedge clk) begin
        if (has_unknown_inputs()) begin
            ready_busy_pending = 1'b0;
            ready_busy_wait_cycles = 0;
        end
        else if (reset) begin
            ready_busy_pending = 1'b0;
            ready_busy_wait_cycles = 0;

            if (!reset_busy_reported) begin
                a_reset_busy_low: assert (!busy)
                    else begin
                        reset_busy_reported = 1'b1;
                        `uvm_error("SVA_RESET_BUSY", "busy must be low while reset is asserted")
                    end
            end

            if (!reset_cwr_reported) begin
                a_reset_cwr_low: assert (!cwr)
                    else begin
                        reset_cwr_reported = 1'b1;
                        `uvm_error("SVA_RESET_CWR", "cwr must be low while reset is asserted")
                    end
            end

            if (!reset_crd_reported) begin
                a_reset_crd_low: assert (!crd)
                    else begin
                        reset_crd_reported = 1'b1;
                        `uvm_error("SVA_RESET_CRD", "crd must be low while reset is asserted")
                    end
            end
        end
        else begin
            reset_busy_reported = 1'b0;
            reset_cwr_reported = 1'b0;
            reset_crd_reported = 1'b0;

            a_cwr_legal_csel: assert (!cwr || (csel == 3'b001) || (csel == 3'b011))
                else `uvm_error("SVA_CWR_ILLEGAL_CSEL",
                    $sformatf("cwr requires csel 001 or 011, got %03b", csel))

            a_l1_write_addr_in_range: assert (!(cwr && (csel == 3'b011)) ||
                                              (caddr_wr < 12'd1024))
                else `uvm_error("SVA_L1_ADDR_OOB",
                    $sformatf("layer1 write address out of range=%0d", caddr_wr))

            if (busy && ready_busy_pending) begin
                ready_busy_pending = 1'b0;
                ready_busy_wait_cycles = 0;
            end
            else if (!busy && !ready_busy_pending && ready) begin
                ready_busy_pending = 1'b1;
                ready_busy_wait_cycles = 0;
            end
            else if (!busy && ready_busy_pending) begin
                if ((ready_busy_wait_cycles + 1) >= READY_BUSY_TIMEOUT_CYCLES) begin
                    a_ready_to_busy_bounded: assert (busy)
                        else `uvm_error("SVA_READY_BUSY_TIMEOUT",
                            $sformatf("busy did not assert within %0d cycles after ready",
                                    READY_BUSY_TIMEOUT_CYCLES))
                    ready_busy_pending = 1'b0;
                    ready_busy_wait_cycles = 0;
                end
                else begin
                    ready_busy_wait_cycles++;
                end
            end
        end
    end

endmodule
