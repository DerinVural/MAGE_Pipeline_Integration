module TopModule ( 
    input clk,
    input load,
    input ena,
    input [1:0] amount,
    input [63:0] data,
    output logic [63:0] q
);

    // Internal register to hold the state of the shifter
    logic [63:0] q_reg;

    // Next state calculation (Combinational Logic)
    logic [63:0] next_q;

    always @(*) begin
        next_q = q_reg;

        if (load) begin
            // Case 1: Load is active
            next_q = data;
        end else if (ena) begin
            // Case 2: Shifting is active
            case (amount) 
                2'b00: begin // Shift Left by 1
                    // Left shift 1: MSB becomes 0, LSB gets old MSB
                    next_q = (q_reg << 1'b1) | 1'b0;
                end
                2'b01: begin // Shift Left by 8
                    // Left shift 8: MSB 8 bits are filled with 0
                    next_q = (q_reg << 8'b1) | 8'b0;
                end
                2'b10: begin // Arithmetic Right Shift by 1
                    // ARS by 1: New MSB (bit 63) must be the old MSB (q_reg[63])
                    // Logical shift right: q_reg >> 1
                    // Sign extension: q_reg[63] << 63
                    next_q = (q_reg >> 1) | (q_reg[63] << 63);
                end
                2'b11: begin // Arithmetic Right Shift by 8
                    // ARS by 8: New MSB 8 bits must be the old MSB (q_reg[63])
                    // Logical shift right: q_reg >> 8
                    // Sign extension: q_reg[63] << (64 - 8)
                    next_q = (q_reg >> 8) | (q_reg[63] << 56);
                end
                default: begin
                    next_q = q_reg; // No change if amount is undefined
                end
            endcase
        end
        // If ena=0 and load=0, next_q remains q_reg (handled by initialization of next_q = q_reg)
    end

    // Sequential Logic (Register Update)
    always @(posedge clk)
    begin
        if (load) begin
            q_reg <= data;
        end else if (ena) begin
            q_reg <= next_q;
        end
        // If load=0 and ena=0, q_reg holds its previous value (implicit hold)
    end

    // Output assignment
    assign q = q_reg;

    // Initialization block for registers
    initial begin
        q_reg = 64'h0; // Initialize state to zero
    end

endmodule