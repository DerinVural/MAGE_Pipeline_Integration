module TopModule(
    input  logic clk,
    input  logic w,
    input  logic R,
    input  logic E,
    input  logic L,
    output logic Q
);

    // Initialize Q to a known value to avoid X at start of simulation
    initial begin
        Q = 1'b0;
    end

    // Sequential logic for shift register stage
    always @(posedge clk) begin
        if (L) begin
            // Load operation (highest priority)
            Q <= R;
        end else if (E) begin
            // Shift operation
            Q <= w;
        end
        // If neither L nor E is asserted, Q holds its value implicitly
    end

endmodule