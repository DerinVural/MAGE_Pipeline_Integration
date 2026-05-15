module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    input  logic e,
    output logic [24:0] out
);

    assign out[24] = ~a ^ b;
    assign out[23] = ~a ^ c;
    assign out[22] = ~a ^ d;
    assign out[21] = ~a ^ e;
    assign out[20] = ~b ^ c;
    assign out[19] = ~b ^ d;
    assign out[18] = ~b ^ e;
    assign out[17] = ~c ^ d;
    assign out[16] = ~c ^ e;
    assign out[15] = ~d ^ e;
    assign out[14] = ~a ^ a;
    assign out[13] = ~a ^ b;
    assign out[12] = ~a ^ c;
    assign out[11] = ~a ^ d;
    assign out[10] = ~a ^ e;
    assign out[ 9] = ~b ^ a;
    assign out[ 8] = ~b ^ b;
    assign out[ 7] = ~b ^ c;
    assign out[ 6] = ~b ^ d;
    assign out[ 5] = ~b ^ e;
    assign out[ 4] = ~c ^ a;
    assign out[ 3] = ~c ^ b;
    assign out[ 2] = ~c ^ c;
    assign out[ 1] = ~c ^ d;
    assign out[ 0] = ~c ^ e;

endmodule