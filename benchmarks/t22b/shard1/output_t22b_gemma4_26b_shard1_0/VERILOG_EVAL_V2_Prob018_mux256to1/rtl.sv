module TopModule (
    input  logic [255:0] in,
    input  logic [7:0]   sel,
    output logic         out
);

    // The multiplexer selects the bit in 'in' at the index specified by 'sel'.
    // Since sel is 8 bits, it can range from 0 to 255, which covers the entire 'in' vector.
    always @(*) begin
        out = in[sel];
    end

endmodule