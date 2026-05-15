module TopModule(
    input  logic       clk,
    input  logic       load,
    input  logic [511:0] data,
    output logic [511:0] q
);

    logic [511:0] q_next;

    // Initialize q to zero to avoid unknown states
    initial begin
        q = 512'b0;
    end

    // Combinational logic for Rule 110
    always @(*)
    begin
        for (int i = 0; i < 512; i = i + 1) begin
            logic left, center, right;
            
            // Boundary conditions: q[-1] and q[512] are 0
            left   = (i == 511) ? 1'b0 : q[i+1];
            center = q[i];
            right  = (i == 0)   ? 1'b0 : q[i-1];

            // Rule 110 implementation
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

    // Sequential logic
    always @(posedge clk) begin
        if (load) begin
            q <= data;
        end else begin
            q <= q_next;
        end
    end

endmodule