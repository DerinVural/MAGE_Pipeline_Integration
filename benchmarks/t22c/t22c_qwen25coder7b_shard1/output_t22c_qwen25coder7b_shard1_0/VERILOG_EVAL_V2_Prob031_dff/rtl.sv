module TopModule (
    logic clk,
    logic d,
    logic q,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    // Initialization block
    initial begin
        wavedrom_title = 512'h0;
        wavedrom_enable = 0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (wavedrom_enable)
            q <= d;
    end

    // Combinational logic for the testbench purposes
    assign wavedrom_title = "D Flip-Flop";
    assign wavedrom_enable = 1;

endmodule