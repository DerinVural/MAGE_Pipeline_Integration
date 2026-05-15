module TopModule (
    input  logic clk,
    input  logic w,
    input  logic R,
    input  logic E,
    input  logic L,
    output logic Q
);

    // Internal register to hold the state of Q
    logic q_reg;

    // Initialize the register to a known state
    initial begin
        q_reg = 1'b0;
    end

    // Sequential logic triggered on positive clock edge
    always @(posedge clk)
    begin
        if (L) begin
            // Priority 1: Load R
            q_reg <= R;
        end
        else if (E) begin
            // Priority 2: Shift from previous stage w
            q_reg <= w;
        end
        else begin
            // Priority 3: Hold current value
            q_reg <= q_reg;
        end
    end

    // Assign the registered value to the output port
    assign Q = q_reg;

endmodule