module TopModule(
    input clk,
    input reset,
    input x,
    output logic z
);

    // Define states
    localparam [2:0] S000 = 3'b000;
    localparam [2:0] S001 = 3'b001;
    localparam [2:0] S010 = 3'b010;
    localparam [2:0] S011 = 3'b011;
    localparam [2:0] S100 = 3'b100;

    // Current and next state signals
    logic [2:0] state, next_state;

    // Sequential logic for state register
    always @(posedge clk) begin
        if (reset)
            state <= S000;
        else
            state <= next_state;
    end

    // Combinational logic for next state and output
    always @(*) begin
        case (state)
            S000: begin
                if (x)
                    next_state = S001;
                else
                    next_state = S000;
                z = 0;
            end
            S001: begin
                if (x)
                    next_state = S100;
                else
                    next_state = S001;
                z = 0;
            end
            S010: begin
                if (x)
                    next_state = S001;
                else
                    next_state = S010;
                z = 0;
            end
            S011: begin
                if (x)
                    next_state = S010;
                else
                    next_state = S001;
                z = 1;
            end
            S100: begin
                if (x)
                    next_state = S100;
                else
                    next_state = S011;
                z = 1;
            end
            default: begin
                next_state = S000;
                z = 0;
            end
        endcase
    end

endmodule