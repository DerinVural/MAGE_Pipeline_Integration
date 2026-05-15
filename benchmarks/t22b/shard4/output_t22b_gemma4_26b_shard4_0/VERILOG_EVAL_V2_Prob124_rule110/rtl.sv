module TopModule (
    input  logic clk,
    input  logic load,
    input  logic [511:0] data,
    output logic [511:0] q
);

    logic [511:0] q_reg;
    logic [511:0] next_q;

    // Initialize the register to avoid X states
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
    always @(*) begin
        for (int i = 0; i < 512; i++) begin
            logic L, C, R;
            C = q_reg[i];
            // Boundary condition: q[-1] = 0 and q[512] = 0
            L = (i == 511) ? 1'b0 : q_reg[i+1];
            R = (i == 0)   ? 1'b0 : q_reg[i-1];

            // Rule 110 Truth Table mapping:
            // L C R | Next
            // 1 1 1 | 0
            // 1 1 0 | 1
            // 1 0 1 | 1
            // 1 0 0 | 0
            // 0 1 1 | 1
            // 0 1 0 | 1
            // 0 0 1 | 1
            // 0 0 0 | 0
            case ({L, C, R})
                3'b111:  next_q[i] = 1'b0;
                3'b110:  next_q[i] = 1'b1;
                3'b101:  next_q[i] = 1'b1;
                3'b100:  next_q[i] = 1'b0;
                3'b011:  next_q[i] = 1'b1;
                3'b010:  next_q[i] = 1'b1;
                3'b001:  next_q[i] = 1'b1;
                3'b000:  next_q[i] = 1'b0;
                default: next_q[i] = 1'b0;
            endcase
        end
    end

    // Output assignment
    assign q = q_reg;

endmodule