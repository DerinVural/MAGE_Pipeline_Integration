module TopModule(
    input  logic       clk,
    input  logic       load,
    input  logic [1:0] ena,
    input  logic [99:0] data,
    output logic [99:0] q
);

    // Internal register to hold the state
    logic [99:0] q_reg;

    // Initialize the register to avoid X in simulation
    initial begin
        q_reg = 100'b0;
    end

    // Sequential logic for rotation and loading
    always @(posedge clk) begin
        if (load) begin
            // (1) Synchronous load
            q_reg <= data;
        end else begin
            // (2) Rotation logic
            case (ena) 
                2'b01: begin
                    // (a) Rotate right by one bit
                    // Bit 0 goes to bit 99, bits 99:1 go to 98:0
                    q_reg <= {q_reg[0], q_reg[99:1]};
                end
                2'b10: begin
                    // (b) Rotate left by one bit
                    // Bit 99 goes to bit 0, bits 98:0 go to 99:1
                    q_reg <= {q_reg[98:0], q_reg[99]};
                end
                // (c) 2'b00 and 2'b11 do not rotate
                default: begin
                    q_reg <= q_reg;
                end
            endcase
        end
    end

    // Continuous assignment to output port
    assign q = q_reg;

endmodule