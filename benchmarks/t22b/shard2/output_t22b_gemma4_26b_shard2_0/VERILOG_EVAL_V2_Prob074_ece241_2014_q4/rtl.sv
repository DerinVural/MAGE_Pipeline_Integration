module TopModule (
    input  logic clk,
    input  logic x,
    output logic z
);

    // Flip-flop outputs
    logic dff1_out;
    logic dff2_out;
    logic dff3_out;

    // Initialize flip-flops to zero as specified
    initial begin
        dff1_out = 1'b0;
        dff2_out = 1'b0;
        dff3_out = 1'b0;
    end

    // Combinational logic for D-inputs
    logic d1_in;
    logic d2_in;
    logic d3_in;

    always @(*) begin
        // Gate 1: XOR(x, dff1_out)
        d1_in = x ^ dff1_out;
        
        // Gate 2: AND(x, ~dff2_out)
        d2_in = x & (~dff2_out);
        
        // Gate 3: OR(x, ~dff3_out)
        d3_in = x | (~dff3_out);
    end

    // Sequential logic (D Flip-Flops)
    always @(posedge clk) begin
        dff1_out <= d1_in;
        dff2_out <= d2_in;
        dff3_out <= d3_in;
    end

    // Output logic: Three-input NOR gate
    // z = ~(dff1_out | dff2_out | dff3_out)
    assign z = ~(dff1_out | dff2_out | dff3_out);

endmodule