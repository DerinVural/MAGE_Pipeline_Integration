module TopModule (
    input clk,
    input [7:0] in,
    output [7:0] pedge
);

    logic [7:0] prev_in;
    
    // Store previous input values
    always @(posedge clk) begin
        prev_in <= in;
    end
    
    // Detect positive edges
    assign pedge = (prev_in == 8'b0) & (in == 8'b1);
    
endmodule