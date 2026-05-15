module TopModule(
    input  logic       clk,
    input  logic       load,
    input  logic [9:0] data,
    output logic       tc
);

    // Internal counter register
    logic [9:0] count;

    // Initialize counter to 0 to avoid X state
    initial begin
        count = 10'd0;
    end

    // Sequential logic for counter
    always @(posedge clk) begin
        if (load) begin
            // (1) Load the internal counter with the 10-bit data
            count <= data;
        end else begin
            // (2) If load = 0, decrement by 1 if not already 0
            if (count > 10'd0) begin
                count <= count - 1'b1;
            end else begin
                // Once reached 0, stay 0
                count <= 10'd0;
            end
        end
    end

    // Combinational logic for terminal count
    // tc indicates whether the internal counter has reached 0
    always @(*) begin
        if (count == 10'd0) begin
            tc = 1'b1;
        end else begin
            tc = 1'b0;
        end
    end

endmodule