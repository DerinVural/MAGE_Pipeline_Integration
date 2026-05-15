module TopModule (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [7:0] c,
    input  logic [7:0] d,
    output logic [7:0] min
);

    // Implementation to find the minimum of the four 8-bit inputs a, b, c, and d.
    // This uses a continuous assignment with nested ternary operators for clarity in finding min(min(a,b), min(c,d)).
    assign min = (a < b) ? 
                   ((a < c) ? ((a < d) ? a : d) : ((c < d) ? c : d)) : 
                   ((b < c) ? ((b < d) ? b : d) : ((c < d) ? c : d));

endmodule