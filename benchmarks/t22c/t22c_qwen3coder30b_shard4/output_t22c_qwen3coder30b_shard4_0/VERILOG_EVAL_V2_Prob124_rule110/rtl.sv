module TopModule(
    input logic clk,
    input logic load,
    input logic [511:0] data,
    output logic [511:0] q
);

    logic [511:0] q_reg;

    always @(posedge clk) begin
        if (load)
            q_reg <= data;
        else begin
            logic [511:0] next_q;
            for (int i = 0; i < 512; i = i + 1) begin
                logic left, center, right;
                
                // Determine left neighbor
                if (i == 0)
                    left = 1'b0;
                else
                    left = q_reg[i-1];
                
                // Current cell
                center = q_reg[i];
                
                // Determine right neighbor
                if (i == 511)
                    right = 1'b0;
                else
                    right = q_reg[i+1];
                
                // Apply Rule 110 transition rules
                case ({left, center, right})
                    3'b111: next_q[i] = 1'b0;
                    3'b110: next_q[i] = 1'b1;
                    3'b101: next_q[i] = 1'b1;
                    3'b100: next_q[i] = 1'b0;
                    3'b011: next_q[i] = 1'b1;
                    3'b010: next_q[i] = 1'b1;
                    3'b001: next_q[i] = 1'b1;
                    3'b000: next_q[i] = 1'b0;
                    default: next_q[i] = 1'b0;
                endcase
            end
            q_reg <= next_q;
        end
    end

    assign q = q_reg;

endmodule