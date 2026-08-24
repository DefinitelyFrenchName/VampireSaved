`timescale 1ns/1ps
// tb_obj_bank.v — EXHAUSTIVE bench for the CPS-2 WIDE object GFX bank
// (emu/jtcores/cores/cps2w/hdl/jtcps2w_obj_bank.v), 14z-107 slice D3.
//
// WHY THIS RATHER THAN A SAMPLED PROBE INSIDE A 60-MINUTE CORE RUN: the gated
// site is ONE expression, so it can be exercised over its WHOLE input space —
// all 65,536 y-words in both profile states — instead of at whatever sprites
// one replay happens to draw. The core run proves the bank REACHES SDRAM; this
// proves the bank is RIGHT.
//
// FIVE CLAIMS, each an assertion below:
//   1. the STOCK bits never move: bank[1:0] == y[14:13] for every input in
//      both profile states. Whatever the promote does, it cannot disturb the
//      2-bit bank the reference core reads.
//   2. wide_en LOW leaves bank[2] STUCK AT 0 across the entire sweep, so the
//      bank is 0-3 exactly as on the reference core. This is the
//      superset-invariant claim, and it is a claim about all 65,536 inputs.
//   3. wide_en HIGH makes bank[2] == y[12], and it DOES take the value 1 —
//      without which the bench would pass vacuously.
//   4. THE ENCODING CONTRACT WITH THE BUILD. tools/gfx_tiles.py `bank_word`
//      emits 0x0000/0x2000/0x4000/0x6000/0x1000/0x3000 for banks 0-5. Each of
//      those six y-words must decode to its own bank number here. The two
//      halves of the contract live in different languages in different
//      repositories and nothing else checks that they agree.
//   5. THE TERMINATOR TRAP, asserted rather than remembered: none of those six
//      encodings may set y bit 15. `bank << 13` would put bank 4 at 0x8000,
//      which IS the sprite-list terminator — the list would end at the first
//      tenant sprite (docs/project/cps2_wide.md, Correction A2). This is the
//      mistake the whole promote exists to avoid, so the bench states it.
//
// The must-fire controls are copies of the module with the gate BYPASSED
// (fails claim 2) and with bit 2 read from y[15] — the profile's first draft —
// which fails claim 4. tests/test_mister_wide_gate.sh runs all three.
module tb_obj_bank;

reg         wide = 0;
reg  [15:0] y    = 16'h0000;
wire [ 2:0] bank;

integer errors = 0, i, wi, checked = 0, hi_wide = 0, hi_stock = 0;
integer k;
reg [15:0] enc [0:5];
reg [ 2:0] want;

jtcps2w_obj_bank uut( .wide_en( wide ), .table_y( y ), .bank( bank ) );

initial begin
    // tools/gfx_tiles.py bank_word(), transcribed
    enc[0] = 16'h0000; enc[1] = 16'h2000; enc[2] = 16'h4000;
    enc[3] = 16'h6000; enc[4] = 16'h1000; enc[5] = 16'h3000;

    for( wi = 0; wi < 2; wi = wi + 1 ) begin
        wide = (wi != 0);
        for( i = 0; i < 65536; i = i + 1 ) begin
            y = i[15:0];
            #1;
            checked = checked + 1;
            // claim 1: the stock bits
            if( bank[1:0] !== i[14:13] ) begin
                if( errors < 8 )
                    $display("FAIL claim 1 wide=%0d y=%04x: bank[1:0]=%b want %b",
                             wide, i[15:0], bank[1:0], i[14:13]);
                errors = errors + 1;
            end
            // claims 2 and 3: the promoted bit
            want = { wide ? i[12] : 1'b0, i[14:13] };
            if( bank !== want ) begin
                if( errors < 8 )
                    $display("FAIL wide=%0d y=%04x: bank=%b want %b",
                             wide, i[15:0], bank, want);
                errors = errors + 1;
            end
            if( bank[2] ) begin
                if( wide ) hi_wide = hi_wide + 1; else hi_stock = hi_stock + 1;
            end
        end
    end

    // claim 4: the encoding contract with tools/gfx_tiles.py
    wide = 1;
    for( k = 0; k < 6; k = k + 1 ) begin
        y = enc[k]; #1;
        if( bank !== k[2:0] ) begin
            $display("FAIL claim 4: y-word %04x decodes to bank %0d, the build emits it for bank %0d",
                     enc[k], bank, k);
            errors = errors + 1;
        end
        // claim 5: none of them may be a terminator
        if( enc[k][15] ) begin
            $display("FAIL claim 5: the encoding for bank %0d is %04x, which sets y bit 15 — THE SPRITE-LIST TERMINATOR",
                     k, enc[k]);
            errors = errors + 1;
        end
    end
    // ...and the stock four must still be 0-3 with the profile clear
    wide = 0;
    for( k = 0; k < 4; k = k + 1 ) begin
        y = enc[k]; #1;
        if( bank !== k[2:0] ) begin
            $display("FAIL claim 4b: stock y-word %04x decodes to bank %0d with wide_en low, want %0d",
                     enc[k], bank, k);
            errors = errors + 1;
        end
    end

    $display("checked %0d vectors; bank[2] set in %0d wide / %0d stock",
             checked, hi_wide, hi_stock);
    if( hi_stock != 0 ) begin
        $display("FAIL claim 2: bank[2] MOVED %0d times with wide_en low - the profile gate is not gating",
                 hi_stock);
        errors = errors + 1;
    end
    if( hi_wide == 0 ) begin
        $display("FAIL claim 3: bank[2] never set with wide_en high - the promote is unreachable, so the bench proves nothing");
        errors = errors + 1;
    end
    if( errors == 0 ) $display("PASS tb_obj_bank");
    else              $display("FAIL tb_obj_bank: %0d error(s)", errors);
    $finish;
end

endmodule
