module TopModule (input clk, input in, output logic out);

logic d;

always @(*) begin
    d = in ^ out;
end

always @(posedge clk) begin
    out <= d;
end

initial begin
    out = 0;
end

endmodule