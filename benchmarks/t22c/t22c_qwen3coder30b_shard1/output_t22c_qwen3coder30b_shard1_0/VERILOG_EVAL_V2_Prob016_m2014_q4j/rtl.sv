module TopModule (
    input [3:0] x,
    input [3:0] y,
    output [4:0] sum
);

    // Internal signals for carry propagation
    logic c0, c1, c2, c3;

    // Full Adder for LSB (bit 0)
    assign sum[0] = x[0] ^ y[0] ^ c0;
    assign c0 = (x[0] & y[0]) | (x[0] & c0) | (y[0] & c0);

    // Full Adder for bit 1
    assign sum[1] = x[1] ^ y[1] ^ c1;
    assign c1 = (x[1] & y[1]) | (x[1] & c0) | (y[1] & c0);

    // Full Adder for bit 2
    assign sum[2] = x[2] ^ y[2] ^ c2;
    assign c2 = (x[2] & y[2]) | (x[2] & c1) | (y[2] & c1);

    // Full Adder for bit 3 (MSB)
    assign sum[3] = x[3] ^ y[3] ^ c3;
    assign c3 = (x[3] & y[3]) | (x[3] & c2) | (y[3] & c2);

    // Overflow bit is the carry-out from the MSB
    assign sum[4] = c3;

endmodule