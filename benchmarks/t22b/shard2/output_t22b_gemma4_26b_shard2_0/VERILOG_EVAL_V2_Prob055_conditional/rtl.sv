module TopModule (
    input  logic [7:0] a,
    input  logic [7:0] b,
    input  logic [7:0] c,
    input  logic [7:0] d,
    output logic [7:0] min
);

    // Combinational logic to find the minimum of four values
    always @(*) begin
        logic [7:0] current_min;
        
        // Initialize current_min with the first input
        current_min = a;
        
        // Compare with b
        if (b < current_min) begin
            current_min = b;
        end
        
        // Compare with c
        if (c < current_min) begin
            current_min = c;
        end
        
        // Compare with d
        if (d < current_min) begin
            current_min = d;
        end
        
        // Assign the result to the output
        min = current_min;
    end

endmodule