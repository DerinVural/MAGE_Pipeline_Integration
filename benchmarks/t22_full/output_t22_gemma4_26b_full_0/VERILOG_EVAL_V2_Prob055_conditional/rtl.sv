module TopModule(
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [7:0] c,
    input  logic [7:0] d,
    output logic [7:0] min
);

    // Combinational logic to find the minimum of four values
    // Step 1: min_ab = min(a, b)
    // Step 2: min_abc = min(min_ab, c)
    // Step 3: min = min(min_abc, d)

    logic [7:0] min_ab;
    logic [7:0] min_abc;

    always @(*) begin
        // Compare a and b
        if (a < b) begin
            min_ab = a;
        end else begin
            min_ab = b;
        end

        // Compare min_ab and c
        if (min_ab < c) begin
            min_abc = min_ab;
        end else begin
            min_abc = c;
        end

        // Compare min_abc and d
        if (min_abc < d) begin
            min = min_abc;
        end else begin
            min = d;
        end
    end

endmodule