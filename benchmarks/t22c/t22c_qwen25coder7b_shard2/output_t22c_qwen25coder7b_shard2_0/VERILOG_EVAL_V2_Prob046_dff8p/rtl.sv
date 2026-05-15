module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic [7:0] d,
    output logic [7:0] q
);

    // Registers for output q and D flip-flops
    logic [7:0] q_reg;
    logic [7:0] dffs [7:0];

    // Initialize D flip-flops in an initial block
    initial begin
        dffs = '{default: 0};
    end

    // Sequential logic for D flip-flops
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            dffs = '{default: 0};
        else begin
            dffs[7] <= d;
            for (integer i = 0; i < 6; i++) begin
                dffs[i] <= dffs[i+1];
            end
        end
    end

    // Assign output q from the last D flip-flop
    assign q_reg = dffs[0];

    // Optionally synchronize q_reg with clk to ensure proper timing
    logic [7:0] q_sync;
    always_ff @(posedge clk) begin
        q_sync <= q_reg;
    end

    // Connect q to the synchronized output
    assign q = q_sync;

endmodule