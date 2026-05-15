module TopModule(
    input logic clk,
    input logic d,
    output logic q
);

    // Internal signals for storing values on each clock edge
    logic d_posedge;
    logic d_negedge;
    
    // Register to store previous clock value for edge detection
    logic clk_prev;
    
    // Initialize internal signals
    initial begin
        clk_prev <= 1'b0;
        d_posedge <= 1'b0;
        d_negedge <= 1'b0;
    end

    // Flip-flop triggered on positive edge of clock
    always @(posedge clk) begin
        d_posedge <= d;
    end

    // Flip-flop triggered on negative edge of clock
    always @(negedge clk) begin
        d_negedge <= d;
    end

    // Combinational logic to select value based on current clock edge
    always @(*) begin
        if (clk) begin
            q = d_posedge;
        end else begin
            q = d_negedge;
        end
    end

endmodule