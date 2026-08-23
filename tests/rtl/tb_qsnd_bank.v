`timescale 1ns/1ps
// tb_qsnd_bank.v — EXHAUSTIVE bench for the CPS-2 WIDE QSound sample-bank
// latch (emu/jtcores/cores/cps2w/hdl/jtcps2w_qsnd_bank.v), 14z-107 slice D1.
//
// WHAT IT PROVES, and why this rather than a sampled probe inside a 45-minute
// core simulation: the gated site is ONE expression, so it can be exercised
// over its WHOLE input space — all 65,536 values of dsp_ab in both profile
// states — instead of at whatever handful of addresses one replay happens to
// visit. Three claims, each an assertion below:
//   1. wide_en LOW is bit-for-bit the stock latch: bank[6:0] == dsp_ab[6:0]
//      and bank[7] is STUCK AT 0 across the entire sweep (this is
//      "qsnd_addr[23] cannot move when the gate is clear").
//   2. wide_en HIGH latches all eight bits, and bank[7] DOES take the value 1
//      (this is "qsnd_addr[23] moves when the gate is set").
//   3. the latch fires only on dsp_ab[15] && cen_cko, and resets to 0 —
//      unchanged from the stock block it was lifted out of.
// The must-fire control is a copy of the module with the gate BYPASSED; it
// must fail claim 1. tests/test_mister_wide_gate.sh runs both.
module tb_qsnd_bank;

reg         rst = 1, clk = 0, cen = 0, wide = 0;
reg  [15:0] ab  = 16'h0000;
wire [ 7:0] bank;

integer errors = 0, i, wi, hi_wide = 0, hi_stock = 0, checked = 0;
reg [7:0] want, prev;

jtcps2w_qsnd_bank uut(
    .rst( rst ), .clk( clk ), .cen_cko( cen ), .wide_en( wide ),
    .dsp_ab( ab ), .bank( bank ) );

always #5 clk = ~clk;

initial begin
    @(negedge clk); @(negedge clk); rst = 0; #1;
    if( bank !== 8'd0 ) begin
        $display("FAIL reset: bank=%02x, want 00", bank); errors = errors + 1;
    end

    for( wi = 0; wi < 2; wi = wi + 1 ) begin
        wide = (wi != 0);
        for( i = 0; i < 65536; i = i + 1 ) begin
            @(negedge clk);
            ab   = i[15:0];
            cen  = 1;
            prev = bank;
            want = i[15] ? (wide ? i[7:0] : {1'b0, i[6:0]}) : prev;
            @(posedge clk); #1;
            checked = checked + 1;
            if( bank !== want ) begin
                if( errors < 8 )
                    $display("FAIL wide=%0d ab=%04x: bank=%02x want %02x",
                             wide, i[15:0], bank, want);
                errors = errors + 1;
            end
            if( bank[7] ) begin
                if( wide ) hi_wide = hi_wide + 1; else hi_stock = hi_stock + 1;
            end
        end
    end

    // the latch must ignore cen_cko low, even in external space
    @(negedge clk); wide = 1; ab = 16'h80AA; cen = 1; @(posedge clk); #1;
    @(negedge clk); ab = 16'h8055; cen = 0; @(posedge clk); #1;
    if( bank !== 8'hAA ) begin
        $display("FAIL cen_cko low still latched: bank=%02x, want AA", bank);
        errors = errors + 1;
    end
    // ...and reset must clear it
    @(negedge clk); rst = 1; @(posedge clk); #1;
    if( bank !== 8'd0 ) begin
        $display("FAIL rst did not clear: bank=%02x", bank); errors = errors + 1;
    end

    $display("checked %0d vectors; bank[7] set in %0d wide / %0d stock",
             checked, hi_wide, hi_stock);
    if( hi_stock != 0 ) begin
        $display("FAIL claim 1: bank[7] MOVED %0d times with wide_en low - the profile gate is not gating", hi_stock);
        errors = errors + 1;
    end
    if( hi_wide == 0 ) begin
        $display("FAIL claim 2: bank[7] never set with wide_en high - the widened latch is unreachable, so the bench proves nothing");
        errors = errors + 1;
    end
    if( errors == 0 ) $display("PASS tb_qsnd_bank");
    else              $display("FAIL tb_qsnd_bank: %0d error(s)", errors);
    $finish;
end

endmodule
