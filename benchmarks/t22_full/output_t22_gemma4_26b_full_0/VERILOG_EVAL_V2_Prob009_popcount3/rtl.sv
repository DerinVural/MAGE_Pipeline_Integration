module TopModule(
    input  logic [2:0] in,
    output logic [1:0] out
);

    // Combinational logic to calculate the population count
    // The number of '1's in a 3-bit vector can be calculated by summing the bits.
    always @(*) begin
        out = in[0] + in[1] + in[2];
    end

endmodule