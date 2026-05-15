module TopModule (
    input clk,
    input load,
    input [9:0] data,
    output logic tc
);

    logic [9:0] counter;
    
    // Sequential logic: counter updates on positive edge of clk
    always @(posedge clk) begin
        if (load)
            counter <= data;
        else if (counter != 0)
            counter <= counter - 1;
        // If counter is already 0, it stays 0
    end
    
    // Continuous assignment for output tc
    assign tc = (counter == 0) ? 1'b1 : 1'b0;
    
endmodule