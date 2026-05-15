module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic in,
    output logic out
);

    // State encoding
    localparam logic [1:0] STATE_A = 2'b00;
    localparam logic [1:0] STATE_B = 2'b01;
    localparam logic [1:0] STATE_C = 2'b10;
    localparam logic [1:0] STATE_D = 2'b11;

    // State registers
    logic [1:0] current_state;
    logic [1:0] next_state;

    // Initialize state to avoid X in simulation
    initial begin
        current_state = STATE_A;
    end

    // Sequential logic for state transitions
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            current_state <= STATE_A;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = current_state;
        case (current_state) 
            STATE_A: begin
                if (in == 1'b0) next_state = STATE_A;
                else           next_state = STATE_B;
            end
            STATE_B: begin
                if (in == 1'b0) next_state = STATE_C;
                else           next_state = STATE_B;
            end
            STATE_C: begin
                if (in == 1'b0) next_state = STATE_A;
                else           next_state = STATE_D;
            end
            STATE_D: begin
                if (in == 1'b0) next_state = STATE_C;
                else           next_state = STATE_B;
            end
            default: next_state = STATE_A;
        endcase
    end

    // Combinational logic for Moore output
    always @(*) begin
        if (current_state == STATE_D) begin
            out = 1'b1;
        end else begin
            out = 1'b0;
        end
    end

endmodule