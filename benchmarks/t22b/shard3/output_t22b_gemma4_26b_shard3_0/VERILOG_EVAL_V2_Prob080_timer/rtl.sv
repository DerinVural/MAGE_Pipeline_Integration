module TopModule (
    input  logic       clk,
    input  logic       load,
    input  logic [9:0] data,
    output logic       tc
);

    // Internal counter register
    logic [9:0] count;

    // Initialize counter to 0 to avoid X in simulation
    initial begin
        count = 10'd0;
    end

    // Sequential logic for the timer
    always @(posedge clk) begin
        if (load) begin
            // (1) If load = 1, load the internal counter with the 10-bit data
            count <= data;
        end else begin
            // (2) If load = 0, decrement if count > 0, otherwise stay at 0
            if (count > 10'd0) begin
                count <= count - 1'b1;
            end else begin
                count <= 10'd0;
            end
        end
    end

    // Combinational logic for terminal count signal
    // tc is 1 when the counter has reached 0
    assign tc = (count == 10'd0);

endmodule