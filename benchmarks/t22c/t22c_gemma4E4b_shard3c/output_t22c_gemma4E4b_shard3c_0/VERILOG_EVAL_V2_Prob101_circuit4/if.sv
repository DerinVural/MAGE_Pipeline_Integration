module TopModule (
    input  a,
    input  b,
    input  c,
    input  d,
    output q
);
// Module body implementation derived from simulation data (Combinational Logic)
assign q = ~( (a == 0'b0 && b == 0'b0 && c == 0'b0 && d == 0'b0) || 
               (a == 0'b0 && b == 0'b0 && c == 0'b0 && d == 1'b1) || 
               (a == 1'b1 && b == 0'b0 && c == 0'b0 && d == 0'b0) || 
               (a == 1'b1 && b == 0'b0 && c == 0'b0 && d == 1'b1) );

endmodule