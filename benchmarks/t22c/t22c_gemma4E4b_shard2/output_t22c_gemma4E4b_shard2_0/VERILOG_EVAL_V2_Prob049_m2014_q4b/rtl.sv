module TopModule (
    input logic clk,
    input logic ar,
    input logic d,
    output logic q
);

    // Internal register to hold the state of the flip-flop
    logic q_reg;

    // Initialization block to set the initial state
    initial begin
        q_reg = 1'b0;
    end

    // Sequential logic for D Flip-Flop with Asynchronous Reset
    // Sensitive to positive edge of clk (for data capture) OR positive edge of ar (for async reset)
    always @(posedge clk or posedge ar) begin
        if (ar) begin
            // Asynchronous Reset (Active High)
            q_reg <= 1'b0;
        end else begin
            // Synchronous Data Load
            q_reg <= d;
        end
    end

    // Output assignment
    assign q = q_reg;

endmodule