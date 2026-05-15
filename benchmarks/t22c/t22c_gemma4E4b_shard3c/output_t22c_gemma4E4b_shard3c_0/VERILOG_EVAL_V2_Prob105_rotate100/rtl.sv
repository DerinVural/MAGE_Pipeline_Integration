module TopModule(
    input  logic clk,
    input  logic load,
    input  logic [1:0] ena,
    input  logic [99:0] data,
    output logic [99:0] q
);

    // Internal register to hold the state of the rotator
    logic [99:0] q_reg;

    // Initialize the register to a known state
    initial begin
        q_reg = 100'h0;
    end

    // Combinational assignment for the output
    assign q = q_reg;

    // Sequential logic block controlled by the clock
    always @(posedge clk) begin
        if (load) begin
            // (1) Load operation: Overrides rotation
            q_reg <= data;
        end else begin
            // (2) Rotation operations (Load is inactive)
            case (ena) 
                2'b01: begin
                    // (a) Rotate Right by one bit
                    // New MSB = Old bit 98, New LSB = Old bit 99
                    // Equivalent to: {q_reg[0], q_reg[99:1]}
                    q_reg <= {q_reg[0], q_reg[99:1]};
                end
                2'b10: begin
                    // (b) Rotate Left by one bit
                    // New LSB = Old bit 99, New MSB = Old bit 98
                    // Equivalent to: {q_reg[98:0], q_reg[99]}
                    q_reg <= {q_reg[98:0], q_reg[99]};
                end
                default: begin
                    // (c) 2'b00 and 2'b11: No rotation, hold current value
                    q_reg <= q_reg;
                end
            endcase
        end
    end

endmodule