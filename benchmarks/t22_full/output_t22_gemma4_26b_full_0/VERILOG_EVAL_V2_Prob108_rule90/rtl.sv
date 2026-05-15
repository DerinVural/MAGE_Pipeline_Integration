module TopModule(
    input  logic             clk,
    input  logic             load,
    input  logic [511:0]    data,
    output logic [511:0]    q
);

    // Internal register to hold the state
    logic [511:0] q_reg;

    // Initialize the register to zero to avoid starting with X
    initial begin
        q_reg = 512'b0;
    end

    // Sequential logic for Rule 90 and Loading
    always @(posedge clk) begin
        if (load) begin
            q_reg <= data;
        end else begin
            // Rule 90: q[i]'s next state is q[i-1] ^ q[i+1]
            // q[i-1] is equivalent to shifting the whole vector left (q << 1)
            // q[i+1] is equivalent to shifting the whole vector right (q >> 1)
            // Boundary conditions: q[-1] = 0 and q[512] = 0 are handled by the zero-filling of shifts.
            q_reg <= (q_reg << 1) ^ (q_reg >> 1);
        end
    end

    // Drive the output
    assign q = q_reg;

endmodule