module TopModule (
    input clk,
    input x,
    input [2:0] y,
    output Y0,
    output z
);

    // Define states
    localparam [2:0] S000 = 3'b000;
    localparam [2:0] S001 = 3'b001;
    localparam [2:0] S010 = 3'b010;
    localparam [2:0] S011 = 3'b011;
    localparam [2:0] S100 = 3'b100;

    // Current and next state registers
    logic [2:0] state;
    logic [2:0] state_next;

    // Temporary variable for output z
    logic z_temp;

    // Initialize state to a known value
    initial begin
        state = S000;
    end

    // Sequential logic for state register
    always @(posedge clk) begin
        state <= state_next;
    end

    // Combinational logic for next state and output
    always @(*) begin
        case (state)
            S000: begin
                if (x == 1'b0)
                    state_next = 3'b000;
                else
                    state_next = 3'b001;
                z_temp = 1'b0;
            end
            S001: begin
                if (x == 1'b0)
                    state_next = 3'b001;
                else
                    state_next = 3'b100;
                z_temp = 1'b0;
            end
            S010: begin
                if (x == 1'b0)
                    state_next = 3'b010;
                else
                    state_next = 3'b001;
                z_temp = 1'b0;
            end
            S011: begin
                if (x == 1'b0)
                    state_next = 3'b001;
                else
                    state_next = 3'b010;
                z_temp = 1'b1;
            end
            S100: begin
                if (x == 1'b0)
                    state_next = 3'b011;
                else
                    state_next = 3'b100;
                z_temp = 1'b1;
            end
            default: begin
                state_next = S000;
                z_temp = 1'b0;
            end
        endcase
    end

    // Assign the temporary output z to the actual output
    assign z = z_temp;

    // Output Y0 is the least significant bit of the next state
    assign Y0 = state_next[0];

endmodule