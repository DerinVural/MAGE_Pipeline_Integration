module TopModule (
    input logic [7:0] a,
    input logic [7:0] b,
    input logic [7:0] c,
    input logic [7:0] d,
    output logic [7:0] min
);

    // Intermediate comparisons
    logic [7:0] comp1;
    logic [7:0] comp2;
    logic [7:0] comp3;

    // Initialize intermediate results to the maximum value
    initial begin
        comp1 = 8'hFF;
        comp2 = 8'hFF;
        comp3 = 8'hFF;
    end

    // Compare a and b
    always @(*) assign comp1 = (a < b) ? a : b;

    // Compare c and d
    always @(*) assign comp2 = (c < d) ? c : d;

    // Compare the results of the previous comparisons
    always @(*) assign comp3 = (comp1 < comp2) ? comp1 : comp2;

    // Assign the final result to min
    always @(*) assign min = comp3;

endmodule