module TopModule (
    input  logic clk,
    input  logic aresetn,
    input  logic x,
    output logic z
);

    // State encoding
    localparam S_RESET = 2'b00;
    localparam S_1     = 2'b01;
    localparam S_10    = 2'b10;

    // State registers
    logic [1:0] current_state;
    logic [1:0] next_state;

    // Initialize state to avoid X
    initial begin
        current_state = S_RESET;
    end

    // Sequential logic: State transition
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            current_state <= S_RESET;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_RESET:
                if (x == 1'b1) begin
                    next_state = S_1;
                end else begin
                    next_state = S_RESET;
                end
            S_1:
                if (x == 1'b0) begin
                    next_state = S_10;
                end else begin
                    next_state = S_1;
                end
            S_10:
                if (x == 1'b1) begin
                    next_state = S_1; // Overlap: '101' detected, current '1' is start of new sequence
                end else begin
                    next_state = S_RESET;
                end
            default:
                next_state = S_RESET;
        endcase
    end

    // Combinational logic: Mealy output
    // Output z is 1 when in S_10 and input x is 1
    always @(*) begin
        if (current_state == S_10 && x == 1'b1) begin
            z = 1'b1;
        end else begin
            z = 1'b0;
        end
    end

endmodule