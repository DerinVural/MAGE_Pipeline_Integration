module TopModule(input logic clk, input logic reset, output logic [9:0] q);

    // Initialize counter to 0
    logic [9:0] counter;
    initial begin
        counter = 0;
    end

    // Sequential logic for counting
    always @(posedge clk) begin
        if (reset)
            counter <= 0;
        else if (counter != 999)
            counter <= counter + 1;
    end

    // Assigning the counter value to the output port
    assign q = counter;

endmodule