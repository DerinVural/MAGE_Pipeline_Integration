module TopModule (
    input  logic clk,
    input  logic resetn,
    input  logic [2:0] r,
    output logic [2:0] g
);

    // State Encoding: A=00, B=01, C=10, D=11
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State Registers
    logic [1:0] current_state;
    logic [1:0] next_state;

    // Initialization block to set initial state (Required for logic without explicit reset)
    initial begin
        current_state = STATE_A;
    end

    // State Flip-Flops (Sequential Logic)
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            current_state <= STATE_A; // Reset to State A
        end else begin
            current_state <= next_state;
        end
    end

    // Next State Logic (Combinational Logic)
    always @(*)
    begin
        next_state = current_state; // Default assignment

        case (current_state)
            STATE_A:
                if (r[0] == 1) begin // R0 request (Highest Priority)
                    next_state = STATE_B;
                end else if (r[1] == 1) begin // R1 request (Second Priority)
                    next_state = STATE_C;
                end else if (r[2] == 1) begin // R2 request (Lowest Priority)
                    next_state = STATE_D;
                end else begin // No requests
                    next_state = STATE_A;
                end
            
            STATE_B: begin // Grant to Device 0
                if (r[0] == 1) begin
                    next_state = STATE_B; // Stay granted
                end else begin
                    next_state = STATE_A; // Request dropped
                end
            end

            STATE_C: begin // Grant to Device 1
                if (r[1] == 1) begin
                    next_state = STATE_C; // Stay granted
                end else begin
                    next_state = STATE_A; // Request dropped
                end
            end

            STATE_D: begin // Grant to Device 2
                if (r[2] == 1) begin
                    next_state = STATE_D; // Stay granted
                end else begin
                    next_state = STATE_A; // Request dropped
                end
            end
        endcase
    end

    // Output Logic (Combinational Assignment)
    // g[i] is asserted if the FSM is in the state granting access to device i
    assign g[0] = (current_state == STATE_B);
    assign g[1] = (current_state == STATE_C);
    assign g[2] = (current_state == STATE_D);

endmodule