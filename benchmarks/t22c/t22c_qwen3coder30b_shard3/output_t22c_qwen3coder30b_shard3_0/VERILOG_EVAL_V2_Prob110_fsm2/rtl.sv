module TopModule (
    input clk,
    input areset,
    input j,
    input k,
    output out
);

    // Define states
    localparam OFF = 1'b0;
    localparam ON  = 1'b1;

    // State register
    logic current_state;
    logic next_state;

    // Sequential logic for state transition
    always @(posedge clk or negedge areset) begin
        if (!areset)
            current_state <= OFF;
        else
            current_state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            OFF: begin
                if (j)
                    next_state = ON;
                else
                    next_state = OFF;
            end
            ON: begin
                if (k)
                    next_state = OFF;
                else
                    next_state = ON;
            end
        endcase
    end

    // Output logic
    assign out = current_state;

endmodule