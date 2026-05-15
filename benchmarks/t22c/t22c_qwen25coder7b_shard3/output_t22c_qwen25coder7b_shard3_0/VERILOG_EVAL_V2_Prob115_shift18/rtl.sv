module TopModule(
    logic clk,
    logic load,
    logic ena,
    logic [1:0] amount,
    logic [63:0] data,
    logic [63:0] q,
    logic reset  // Added reset port
);

    logic [63:0] shift_reg;

    initial begin
        shift_reg = 0;
    end

    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 0;
        end else begin
            if (ena) begin
                case (amount)
                    2'b00: shift_reg <= shift_reg << 1;
                    2'b01: shift_reg <= shift_reg << 8;
                    2'b10: shift_reg <= shift_reg >> 1;
                    2'b11: shift_reg <= shift_reg >> 8;
                    default: ;
                endcase
            end
        end
    end

    always @(*)
        q = shift_reg;

endmodule