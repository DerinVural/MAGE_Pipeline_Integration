module TopModule(
    input  logic             clk,
    input  logic             load,
    input  logic [511:0]    data,
    output logic [511:0]    q
);

    logic [511:0] q_reg;
    logic [511:0] next_q;

    // Initialize q_reg to 0
    initial begin
        q_reg = 512'b0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (load) begin
            q_reg <= data;
        end else begin
            q_reg <= next_q;
        end
    end

    // Combinational logic for Rule 110
    // L[i] = q[i+1], R[i] = q[i-1]
    // Boundary conditions: q[-1] = 0, q[512] = 0
    always @(*) begin
        logic [511:0] L;
        logic [511:0] R;
        logic [511:0] C;

        C = q_reg;
        // L[i] is q[i+1]. For i=511, L[511] = q[512] = 0.
        L = {q_reg[510:0], 1'b0};
        // R[i] is q[i-1]. For i=0, R[0] = q[-1] = 0.
        R = {1'b0, q_reg[511:1]};

        // Rule 110: Next = (C ^ R) | (~L & C & R)
        next_q = (C ^ R) | (~L & C & R);
    end

    // Output assignment
    assign q = q_reg;

endmodule