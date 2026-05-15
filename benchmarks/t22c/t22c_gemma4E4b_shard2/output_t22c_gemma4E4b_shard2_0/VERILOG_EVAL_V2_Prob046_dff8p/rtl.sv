module TopModule (input logic clk,
    input logic reset,
    input logic [7:0] d,
    output logic [7:0] q
);

    // Internal register to hold the state of the 8 DFFs
    logic [7:0] q_reg;

    // Initialization block for known starting state before reset is asserted or stable
    initial begin
        q_reg = 8'h00; // Initialize to 0, although reset handles the desired value 0x34
    end

    // Sequential logic implementation (DFFs triggered by negative clock edge)
    always @(negedge clk)
    begin
        if (reset == 1'b1)
        begin
            // Synchronous active high reset to 0x34
            q_reg <= 8'h34;
        end
        else
        begin
            // Normal data capture on negative edge
            q_reg <= d;
        end
    end

    // Output assignment
    assign q = q_reg;

endmodule