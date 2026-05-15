module TopModule (
    input  logic x,
    input  logic y,
    output logic z
);

    // The truth table derived from the waveform is:
    // x y | z
    // --------- 
    // 0 0 | 1
    // 0 1 | 0
    // 1 0 | 0
    // 1 1 | 1
    // This corresponds to the XNOR operation.

    always @(*) begin
        if (x == y) begin
            z = 1'b1;
        end else begin
            z = 1'b0;
        end
    end

endmodule