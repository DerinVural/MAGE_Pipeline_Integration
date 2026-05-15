module TopModule (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [7:0] c,
    input  logic [7:0] d,
    output logic [7:0] min
);

    assign min = (a <= b && a <= c && a <= d) ? a : 
                 (b <= c && b <= d) ? b :
                 (c <= d) ? c : d;

endmodule