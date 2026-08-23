`timescale 1ns/1ps
// tb_profile.v — bench for the CPS-2 WIDE runtime profile gate
// (emu/jtcores/cores/cps2w/hdl/jtcps2w_profile.v), 14z-107 slice D1.
//
// WHAT IT PROVES. The profile is selected from ONE reserved byte of the MRA
// ROM header, and everything that could make a STOCK download turn the
// profile on is a superset-invariant failure. So:
//   1. a header of the generator's own 0xFF fill leaves wide_en LOW — this is
//      the property that makes stock vsavj on jtcps2w.rbf a stock machine;
//   2. 0xFE at byte 41 raises it;
//   3. it re-defaults at the first byte of the NEXT download, so a second
//      ROM load cannot inherit the first one's profile;
//   4. 0xFE at every OTHER header address, and at an address past the header,
//      leaves it LOW (the address decode is real);
//   5. the NVRAM path (ioctl_ram) never writes it;
//   6. over all 256 values of the byte, wide_en == ~data[0].
// Controls in tests/test_mister_wide_gate.sh: a variant with the address
// check removed must fail 4, and a variant with the polarity flipped must
// fail 1.
module tb_profile;

reg         clk = 0;
reg  [25:0] ioctl_addr = 0;
reg  [ 7:0] ioctl_dout = 8'hff;
reg         ioctl_wr = 0, ioctl_ram = 0;
wire        wide_en;

integer errors = 0, i, a, d;

jtcps2w_profile uut(
    .clk( clk ), .ioctl_addr( ioctl_addr ), .ioctl_dout( ioctl_dout ),
    .ioctl_wr( ioctl_wr ), .ioctl_ram( ioctl_ram ), .wide_en( wide_en ) );

always #5 clk = ~clk;

// stream a 64-byte header: 0xFF everywhere except byte `at`, which gets `val`.
// `at` >= 64 means "0xFF everywhere" (and the byte is written afterwards).
task header;
    input integer at;
    input [7:0]   val;
    input         ram;
    integer k;
    begin
        for( k = 0; k < 64; k = k + 1 ) begin
            @(negedge clk);
            ioctl_addr = k[25:0];
            ioctl_dout = (k == at) ? val : 8'hff;
            ioctl_ram  = (k == at) ? ram : 1'b0;
            ioctl_wr   = 1;
            @(posedge clk);
        end
        @(negedge clk); ioctl_wr = 0; ioctl_ram = 0; #1;
    end
endtask

initial begin
    // 1. the generator's fill: profile OFF
    header(64, 8'hff, 0);
    if( wide_en !== 1'b0 ) begin
        $display("FAIL 1: a 0xFF-filled header turned the profile ON"); errors = errors + 1; end

    // 2. byte 41 = 0xFE: profile ON
    header(41, 8'hfe, 0);
    if( wide_en !== 1'b1 ) begin
        $display("FAIL 2: byte 41 = FE did not raise wide_en"); errors = errors + 1; end

    // 3. the next download re-defaults it
    header(64, 8'hff, 0);
    if( wide_en !== 1'b0 ) begin
        $display("FAIL 3: the profile survived a fresh download"); errors = errors + 1; end

    // 4. every other header address must be inert
    for( a = 0; a < 64; a = a + 1 ) if( a != 41 ) begin
        header(a, 8'hfe, 0);
        if( wide_en !== 1'b0 ) begin
            if( errors < 8 ) $display("FAIL 4: FE at header byte %0d raised wide_en", a);
            errors = errors + 1;
        end
    end
    // ...and so must an address past the header (bulk ROM data)
    header(64, 8'hff, 0);
    @(negedge clk); ioctl_addr = 26'd105; ioctl_dout = 8'hfe; ioctl_wr = 1;
    @(posedge clk); @(negedge clk); ioctl_wr = 0; #1;
    if( wide_en !== 1'b0 ) begin
        $display("FAIL 4b: a ROM-body byte at addr 105 raised wide_en"); errors = errors + 1; end

    // 5. the NVRAM path never writes it
    header(41, 8'hfe, 1);
    if( wide_en !== 1'b0 ) begin
        $display("FAIL 5: ioctl_ram write at byte 41 raised wide_en"); errors = errors + 1; end

    // 6. wide_en == ~data[0] over the whole byte
    for( d = 0; d < 256; d = d + 1 ) begin
        header(41, d[7:0], 0);
        if( wide_en !== ~d[0] ) begin
            if( errors < 12 ) $display("FAIL 6: byte 41 = %02x gave wide_en=%b", d[7:0], wide_en);
            errors = errors + 1;
        end
    end

    if( errors == 0 ) $display("PASS tb_profile");
    else              $display("FAIL tb_profile: %0d error(s)", errors);
    $finish;
end

endmodule
