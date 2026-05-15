module TopModule (
    input  logic [99:0] in,
    output logic [99:0] out
);

    // Implement bit reversal: out[i] = in[99 - i]
    always @(*)
    begin
        for (int i = 0; i < 100; i = i + 1) begin
            out[i] = in[99 - i];
        end
    end

endmodule