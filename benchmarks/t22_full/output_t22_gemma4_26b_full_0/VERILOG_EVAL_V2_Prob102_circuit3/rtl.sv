module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic q
);

    // Combinational logic implementation
    // Based on the truth table derived from the waveform:
    // q = (a | b) & (c | d)
    always @(*) begin
        q = (a | b) & (c | d);
    end

endmodule