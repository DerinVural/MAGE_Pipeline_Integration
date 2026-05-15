module TopModule (
    input logic a,
    input logic b,
    output logic out
);
    // Implementation of NOR gate: out = NOT (a OR b)
    assign out = ~(a | b);
endmodule