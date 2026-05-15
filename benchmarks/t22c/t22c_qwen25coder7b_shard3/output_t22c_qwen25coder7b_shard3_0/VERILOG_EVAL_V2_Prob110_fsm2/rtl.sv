module TopModule (
    logic clk,
    logic areset,
    logic j,
    logic k,
    logic out
);

    // Define states
    localparam OFF = 1'b0;
    localparam ON = 1'b1;

    // State register
    logic currentState;
    logic nextState;

    // Initial block to initialize the state register
    initial begin
        currentState = OFF;
    end

    // Always block for updating the next state based on the current state and inputs
    always @(*) begin
        case (currentState)
            OFF: nextState = (j) ? ON : OFF;
            ON: nextState = (k) ? OFF : ON;
            default: nextState = currentState; // Should not happen
        endcase
    end

    // Always block for capturing the rising edge of the clock
    always @(posedge clk) begin
        if (areset) begin
            currentState <= OFF; // Reset to OFF on active-high asynchronous reset
        end else begin
            currentState <= nextState; // Update state based on next state logic
        end
    end

    // Assign output based on the current state
    assign out = currentState;

endmodule