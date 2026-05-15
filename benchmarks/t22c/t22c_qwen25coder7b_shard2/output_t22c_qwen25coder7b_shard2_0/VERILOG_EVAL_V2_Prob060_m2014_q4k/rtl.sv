module TopModule (
    input  logic clk,
    input  logic resetn,
    input  logic in,
    output logic out
);

    logic [3:0] shift_reg;

    initial begin
        shift_reg = 4'b0000;
    end

    always @(posedge clk) begin
        if (!resetn)
            shift_reg <= 4'b0000;
        else begin
            shift_reg <= {shift_reg[2:0], in};
        end
    end

    assign out = shift_reg[3];

endmodule