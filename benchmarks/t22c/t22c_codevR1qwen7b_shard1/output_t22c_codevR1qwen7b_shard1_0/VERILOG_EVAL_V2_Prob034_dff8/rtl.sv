module TopModule ( input logic clk, input logic [7:0] d, output logic [7:0] q );
    logic [7:0] q_reg;
    initial q_reg = 8'b0;
    always @(posedge clk) begin
        q_reg <= d;
    end
    assign q = q_reg;
endmodule