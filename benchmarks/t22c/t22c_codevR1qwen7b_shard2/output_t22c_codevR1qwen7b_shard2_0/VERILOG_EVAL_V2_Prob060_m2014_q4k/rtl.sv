module TopModule (
    input logic clk,
    input logic resetn,
    input logic in,
    output logic out
);

    // Declare shift register with indices 4 down to 1
    logic [4:1] sr_reg;

    // Initialize register to zero using initial block
    initial begin
        sr_reg = 4'b0;
    end

    // Combinational output assignment
    assign out = sr_reg[4];

    // Shift register update on clock edge with reset
    always @(posedge clk) begin
        if (!resetn) begin
            sr_reg <= 4'b0;
        end else begin
            sr_reg <= {sr_reg[3:1], in}; // Shift right, insert new bit at MSB
        end
    end

endmodule