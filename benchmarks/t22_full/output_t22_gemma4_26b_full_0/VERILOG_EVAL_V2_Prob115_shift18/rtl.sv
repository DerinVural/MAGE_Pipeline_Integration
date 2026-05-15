module TopModule(
    input  logic       clk,
    input  logic       load,
    input  logic       ena,
    input  logic [1:0] amount,
    input  logic [63:0] data,
    output logic [63:0] q
);

    logic [63:0] q_reg;

    // Initialize register to 0 to avoid X in simulation
    initial begin
        q_reg = 64'h0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (load) begin
            // Synchronous load
            q_reg <= data;
        end else if (ena) begin
            // Shift logic
            case (amount)
                2'b00: begin
                    // Shift left by 1 bit
                    q_reg <= q_reg << 1;
                end
                2'b01: begin
                    // Shift left by 8 bits
                    q_reg <= q_reg << 8;
                end
                2'b10: begin
                    // Arithmetic right shift by 1 bit
                    q_reg <= $signed(q_reg) >>> 1;
                end
                2'b11: begin
                    // Arithmetic right shift by 8 bits
                    q_reg <= $signed(q_reg) >>> 8;
                end
                default: ;
            endcase
        end
        // If !load and !ena, q_reg maintains its value
    end

    // Output assignment
    assign q = q_reg;

endmodule