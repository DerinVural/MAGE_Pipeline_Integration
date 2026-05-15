module TopModule (
    input wire clk,
    input wire load,
    input wire [9:0] data,
    input wire reset,
    output wire tc
);

    // Counter register
    logic [9:0] counter;

    // Terminal count flag
    logic tc_flag;

    // Initial block to set initial values
    initial begin
        counter = 10'b0;
        tc_flag = 1'b0;
    end

    // Always block for updating the counter
    always @(posedge clk) begin
        if (reset)
            counter <= 10'b0;
        else if (load)
            counter <= data;
        else if (counter != 0)
            counter <= counter - 1;
    end

    // Always block for calculating the terminal count flag
    always @(*) begin
        tc_flag = (counter == 0);
    end

    // Assign the terminal count flag to the output
    assign tc = tc_flag;

endmodule