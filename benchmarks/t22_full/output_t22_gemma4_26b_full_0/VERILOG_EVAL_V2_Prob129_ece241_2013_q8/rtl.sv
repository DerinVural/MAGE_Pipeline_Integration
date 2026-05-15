module TopModule(
    input  logic clk,
    input  logic aresetn,
    input  logic x,
    output logic z
);

    // State encoding
    localparam STATE_RESET = 2'b00;
    localparam STATE_1     = 2'b01;
    localparam STATE_10    = 2'b10;

    // State registers
    logic [1:0] current_state;
    logic [1:0] next_state;

    // Sequential logic: State transition
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            current_state <= STATE_RESET;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state) 
            STATE_RESET: begin
                if (x == 1'b1) 
                    next_state = STATE_1;
                else 
                    next_state = STATE_RESET;
            end
            STATE_1: begin
                if (x == 1'b1) 
                    next_state = STATE_1;
                else if (x == 1'b0) 
                    next_state = STATE_10;
                else
                    next_state = STATE_1;
            end
            STATE_10: begin
                if (x == 1'b1) 
                    next_state = STATE_1; // Overlap: '101' -> last '1' is start of new sequence
                else if (x == 1'b0) 
                    next_state = STATE_RESET;
                else
                    next_state = STATE_10;
            end
            default: begin
                next_state = STATE_RESET;
            end
        endcase
    end

    // Combinational logic: Mealy Output
    // Output z is 1 when in STATE_10 and input x is 1
    always @(*) begin
        if (current_state == STATE_10 && x == 1'b1) begin
            z = 1'b1;
        end else begin
            z = 1'b0;
        end
    end

endmodule