module stimulus_gen (
    input clk,
    output logic a,
    output logic b,
    output logic q
);

    // Combinational logic
    assign q = a & b;

endmodule