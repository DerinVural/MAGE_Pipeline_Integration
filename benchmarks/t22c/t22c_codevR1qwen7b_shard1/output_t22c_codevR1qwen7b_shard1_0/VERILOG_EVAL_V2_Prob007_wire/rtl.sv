module TopModule (
    input in,
    output out
);
    assign out = in;
endmodule

module stimulus_gen (
    input clk,
    output logic in,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);
    logic [1:0] clk_gen;
    logic in_reg;
    logic wavedrom_enable_reg;

    initial begin
        clk_gen = 0;
        forever #5 clk_gen = ~clk_gen;
    end

    assign clk = clk_gen;

    initial begin
        in_reg = 0;
        wavedrom_enable_reg = 0;
        wavedrom_title = 0;
    end
endmodule