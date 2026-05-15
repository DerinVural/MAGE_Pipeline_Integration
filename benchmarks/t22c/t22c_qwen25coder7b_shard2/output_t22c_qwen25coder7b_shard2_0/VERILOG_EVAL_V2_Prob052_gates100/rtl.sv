module TopModule (
    input logic clk,
    input logic reset,
    input logic [99:0] in,
    output logic out_and,
    output logic out_or,
    output logic out_xor,
    output wire [511:0] wavedrom_title,
    output wire wavedrom_enable
);

    assign out_and = &in;
    assign out_or = |in;

    logic [99:0] xor_result;
    logic wavedrom_enable_reg;

    always @(*) begin
        xor_result = in[0];
        for (int i = 1; i <= 99; i++) begin
            xor_result ^= in[i];
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            wavedrom_title <= 512'h0;
            wavedrom_enable_reg <= 0;
        end else begin
            wavedrom_title <= "AND, OR, XOR Outputs";
            wavedrom_enable_reg <= 1;
        end
    end

    assign out_xor = xor_result;
    assign wavedrom_enable = wavedrom_enable_reg;

endmodule;