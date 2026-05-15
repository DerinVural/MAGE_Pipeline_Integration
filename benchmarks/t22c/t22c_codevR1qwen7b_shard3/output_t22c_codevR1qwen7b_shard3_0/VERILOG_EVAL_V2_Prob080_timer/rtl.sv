module TopModule (input logic clk, input logic load, input logic [9:0] data, output logic tc);
    logic [9:0] counter;
    initial counter = 10'd0;
    always @(posedge clk) begin
        if (load)
            counter <= data;
        else if (counter != 0)
            counter <= counter - 1;
    end
    assign tc = (counter == 10'd0);
endmodule