module TopModule (input clk, input d, input q);
    logic q_reg;
    assign q = q_reg;
    always @(posedge clk) begin
        q_reg <= d;
    end
endmodule