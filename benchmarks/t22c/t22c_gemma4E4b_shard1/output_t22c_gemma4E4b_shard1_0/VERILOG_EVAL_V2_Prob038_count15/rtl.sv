module TopModule(
    input  logic clk,
    input  logic reset,
    output logic [3:0] q
);

    // Internal register to hold the current count
    logic [3:0] count;

    // Initialize the counter to 0 at simulation start
    initial begin
        count = 4'b0;
    end

    // Sequential logic for the counter
    always @(posedge clk)
    begin
        if (reset)
            count <= 4'b0;
        else
            // Increment the counter. Since it's 4-bit, it automatically wraps 15 -> 0
            count <= count + 1;
    end

    // Assign the internal count register to the output port
    assign q = count;

endmodule