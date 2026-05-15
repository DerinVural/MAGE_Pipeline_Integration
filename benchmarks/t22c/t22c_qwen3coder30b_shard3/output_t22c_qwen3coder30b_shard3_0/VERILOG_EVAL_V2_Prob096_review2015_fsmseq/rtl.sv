module TopModule (
    input clk,
    input reset,
    input data,
    output start_shifting
);

    // Define states
    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;

    // State register
    logic [2:0] state, next_state;

    // Sequential logic for state register
    always @(posedge clk) begin
        if (reset)
            state <= S0;
        else
            state <= next_state;
    end

    // Combinational logic for next state and output
    always @(*) begin
        case (state)
            S0: begin
                if (data)
                    next_state = S1;
                else
                    next_state = S0;
            end
            S1: begin
                if (data)
                    next_state = S2;
                else
                    next_state = S0;
            end
            S2: begin
                if (!data)
                    next_state = S3;
                else
                    next_state = S1;
            end
            S3: begin
                if (data)
                    next_state = S4;
                else
                    next_state = S0;
            end
            S4: begin
                next_state = S4;
            end
            default: next_state = S0;
        endcase
    end

    // Output logic
    assign start_shifting = (state == S4);

endmodule