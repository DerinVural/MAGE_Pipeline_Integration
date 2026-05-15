module TopModule (
    input  logic [255:0] in,
    input  logic [7:0] sel,
    output logic out
);

    // Implement a 256-to-1 MUX: out selects in[sel[7:0]]
    // Since sel is 8 bits, it selects index 0 through 255 from the 256-bit input 'in'.
    assign out = in[sel];

endmodule