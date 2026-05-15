module TopModule (
    input logic a,
    input logic b,
    output logic out
);
    // NOR gate implementation
    assign out = ~(a | b);
endmodule