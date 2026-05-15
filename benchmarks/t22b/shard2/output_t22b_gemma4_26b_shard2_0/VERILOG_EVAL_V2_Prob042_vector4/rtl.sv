module TopModule (
    input  logic [7:0]  in,
    output logic [31:0] out
);

    // Sign extension logic
    // Replicate the sign bit (in[7]) 24 times and concatenate with the original 8-bit input
    assign out = {{24{in[7]}}, in};

endmodule