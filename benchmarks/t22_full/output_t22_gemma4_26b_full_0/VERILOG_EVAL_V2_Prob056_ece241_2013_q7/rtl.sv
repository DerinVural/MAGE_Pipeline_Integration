module TopModule(
    input  logic clk,
    input  logic j,
    input  logic k,
    output logic Q
);

    // Initialize Q to a known value to avoid 'X' at start of simulation
    initial begin
        Q = 1'b0;
    end

    // Sequential logic for JK Flip-Flop
    always @(posedge clk) begin
        if (j == 1'b0 && k == 1'b0) begin
            // Hold mode
            Q <= Q;
        end else if (j == 1'b0 && k == 1'b1) begin
            // Reset mode
            Q <= 1'b0;
        end else if (j == 1'b1 && k == 1'b0) begin
            // Set mode
            Q <= 1'b1;
        end else if (j == 1'b1 && k == 1'b1) begin
            // Toggle mode
            Q <= ~Q;
        end
    end

endmodule