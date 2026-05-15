module stimulus_gen (
    input clk,
    output logic a,
    output logic b,
    output logic sel_b1,
    output logic sel_b2,
    output reg [511:0] wavedrom_title,
    output reg wavedrom_enable
);
    localparam SEL_B = 2'b11;
    initial begin
        a = 1'b0;
        b = 1'b0;
        sel_b1 = 1'b0;
        sel_b2 = 1'b0;
        wavedrom_enable = 1'b0;
        wavedrom_title = 512'b0;
    end
    always @(*) begin
        if (sel_b1 && sel_b2) begin
            b = 1'b1;
            a = 1'b0;
        end else begin
            a = 1'b1;
            b = 1'b0;
        end
    end
endmodule