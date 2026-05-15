module TopModule (
    input clk,
    input areset,
    input load,
    input ena,
    input [3:0] data,
    output [3:0] q
);

    // Register declaration
    logic [3:0] q_reg;

    // Asynchronous reset logic
    always @(posedge clk or posedge areset) begin
        if (areset)
            q_reg <= 4'b0;
        else begin
            // Synchronous load and enable logic
            if (load)
                q_reg <= data;
            else if (ena)
                q_reg <= {1'b0, q_reg[3:1]};
        end
    end

    // Output assignment
    assign q = q_reg;

endmodule