module TopModule (
    input clk,
    input reset,
    input [31:0] in,
    output [31:0] out
);

    // Storage for previous input values
    logic [31:0] prev_in;
    
    // Temporary logic to hold the computed output
    logic [31:0] temp_out;
    
    // Combinational logic to determine output
    always @(*) begin
        temp_out = 0;
        for (int i = 0; i < 32; i = i + 1) begin
            if (prev_in[i] == 1 && in[i] == 0)
                temp_out[i] = 1;
        end
    end
    
    // Assign the temporary value to the output
    assign out = temp_out;
    
    // Sequential logic to update previous input
    always @(posedge clk) begin
        if (reset)
            prev_in <= 0;
        else
            prev_in <= in;
    end

endmodule