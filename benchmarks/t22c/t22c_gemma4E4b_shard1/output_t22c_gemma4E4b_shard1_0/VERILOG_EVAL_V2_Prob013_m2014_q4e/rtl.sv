module TopModule(
    input logic in1,
    input logic in2,
    output logic out
);

    // Implementation of 2-input NOR gate: out = NOT (in1 OR in2)
    assign out = ~(in1 | in2);

endmodule