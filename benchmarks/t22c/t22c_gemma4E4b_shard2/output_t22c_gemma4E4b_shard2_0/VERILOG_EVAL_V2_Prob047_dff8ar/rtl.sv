module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // Internal register to hold the state of the DFFs
    logic [7:0] q_reg;

    // Initialize the register to 0 before simulation starts
    initial begin
        q_reg = 8'b0;
    end

    // Sequential logic for the 8 D flip-flops with active-high asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Asynchronous reset: force output to 0
            q_reg <= 8'b0;
        end else begin
            // Synchronous data loading on positive clock edge
            q_reg <= d;
        end
    end

    // Drive the output port from the internal register
    assign q = q_reg;

endmodule