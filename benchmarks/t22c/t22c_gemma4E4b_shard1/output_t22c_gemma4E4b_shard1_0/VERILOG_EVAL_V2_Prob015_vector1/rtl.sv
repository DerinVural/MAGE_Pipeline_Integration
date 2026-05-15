module TopModule (
    input  logic [15:0] in,
    output logic [7:0] out_hi,
    output logic [7:0] out_lo
);

    // Implementation of the circuit to split the 16-bit input into high and low bytes.
    // out_hi takes the upper 8 bits [15:8]
    assign out_hi = in[15:8];
    
    // out_lo takes the lower 8 bits [7:0]
    assign out_lo = in[7:0];

endmodule