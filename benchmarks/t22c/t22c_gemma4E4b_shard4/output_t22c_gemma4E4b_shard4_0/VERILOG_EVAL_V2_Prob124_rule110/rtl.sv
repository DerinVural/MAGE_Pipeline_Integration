module TopModule_if(
    input  logic clk,
    input  logic load,
    input  logic [511:0] data,
    output logic [511:0] q
);

    // Internal signals for computation
    logic [511:0] q_next;
    
    // 1. Combinatorial Logic: Calculate the next state (q_next) based on current state (q) and Rule 110
    // Always @(*) ensures that q_next updates whenever q changes.
    always @(*)
    begin
        for (int i = 0; i < 512; i = i + 1) begin
            // Determine neighbors, applying boundary condition (q[-1]=0, q[512]=0)
            logic left = (i == 0) ? 1'b0 : q[i-1];
            logic center = q[i];
            logic right = (i == 511) ? 1'b0 : q[i+1];

            // Map (Left, Center, Right) to Next State using Rule 110 table:
            // (1, 1, 1) -> 0
            // (1, 1, 0) -> 1
            // (1, 0, 1) -> 1
            // (1, 0, 0) -> 0
            // (0, 1, 1) -> 1
            // (0, 1, 0) -> 1
            // (0, 0, 1) -> 1
            // (0, 0, 0) -> 0

            case ({left, center, right})
                3'b111: q_next[i] = 1'b0;
                3'b110: q_next[i] = 1'b1;
                3'b101: q_next[i] = 1'b1;
                3'b100: q_next[i] = 1'b0;
                3'b011: q_next[i] = 1'b1;
                3'b010: q_next[i] = 1'b1;
                3'b001: q_next[i] = 1'b1;
                3'b000: q_next[i] = 1'b0;
                default: q_next[i] = 1'b0;
            endcase
        end
    end

    // 2. Sequential Logic: Update the output register 'q'
    // Initialize 'q' to zero to ensure a known starting state (preventing X outputs).
    initial begin
        q = {512{1'b0}};
    end

    always @(posedge clk)
    begin
        if (load == 1'b1)
        begin
            // Synchronous Load
            q <= data;
        end
        else
        begin
            // Synchronous Calculation (next state)
            q <= q_next;
        end
    end

endmodule