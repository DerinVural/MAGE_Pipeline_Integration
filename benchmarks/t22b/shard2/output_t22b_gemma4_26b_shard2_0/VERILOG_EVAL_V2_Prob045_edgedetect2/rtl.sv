module TopModule (
    input  logic       clk,
    input  logic [7:0] in,
    output logic [7:0] anyedge
);

    // Signal to store the previous state of the input
    logic [7:0] in_delayed;

    // Initialize register to prevent X in simulation
    initial begin
        in_delayed = 8'b0;
    end

    // Sequential logic: capture the input on the rising edge
    always @(posedge clk) begin
        in_delayed <= in;
    end

    // Combinational logic: detect edge via XOR
    // anyedge[i] is 1 if in[i] != in_delayed[i]
    assign anyedge = in ^ in_delayed;

endmodule