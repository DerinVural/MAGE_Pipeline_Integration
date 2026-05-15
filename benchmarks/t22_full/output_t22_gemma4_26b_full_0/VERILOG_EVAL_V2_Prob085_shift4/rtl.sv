module TopModule(
    input  logic       clk,
    input  logic       areset,
    input  logic       load,
    input  logic       ena,
    input  logic [3:0] data,
    output logic [3:0] q
);

    // Sequential logic
    // areset is asynchronous, positive edge triggered.
    // load has higher priority than ena.
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            q <= 4'b0000;
        end else if (load) begin
            q <= data;
        end else if (ena) begin
            // Right shift: q[3] becomes 0, q[2] gets q[3], etc.
            // q[0] is shifted out.
            q <= {1'b0, q[3:1]};
        end
        // If neither load nor ena is asserted, q retains its value
    end

endmodule