module TopModule (
    input  logic clk,
    input  logic load,
    input  logic [9:0] data,
    output logic tc
);

    // Internal counter: 10 bits wide
    logic [9:0] counter;

    // Combinational assignment for output tc
    // tc is high when the counter reaches 0
    assign tc = (counter == 10'h0);

    // Sequential logic (Counter update)
    always @(posedge clk)
    begin
        if (load) begin
            // (1) Load operation: Load counter with 'data'
            counter <= data;
        end else begin
            // (2) Decrement operation: Decrement by 1, but hold at 0 if already 0
            if (counter > 10'h0) begin
                counter <= counter - 1;
            end else begin
                // Stop counting: If it's 0, it stays 0
                counter <= 10'h0;
            end
        end
    end

    // Initialization (Requirement #3: Initialize sequential elements)
    initial begin
        counter = 10'h0;
    end

endmodule