module TopModule (
    input  logic        clk,
    input  logic        load,
    input  logic        ena,
    input  logic [1:0]  amount,
    input  logic [63:0] data,
    output logic [63:0] q
);

    // Initialize register to 0 to avoid X state
    initial begin
        q = 64'b0;
    end

    // Sequential logic for load and shift
    always @(posedge clk) begin
        if (load) begin
            q <= data;
        end else if (ena) begin
            case (amount)
                2'b00: begin
                    // Shift left by 1
                    q <= q << 1;
                end
                2'b01: begin
                    // Shift left by 8
                    q <= q << 8;
                end
                2'b10: begin
                    // Arithmetic right shift by 1
                    // Use $signed to ensure sign extension
                    q <= $signed(q) >>> 1;
                end
                2'b11: begin
                    // Arithmetic right shift by 8
                    q <= $signed(q) >>> 8;
                end
                default: ;
            endcase
        end
    end

endmodule