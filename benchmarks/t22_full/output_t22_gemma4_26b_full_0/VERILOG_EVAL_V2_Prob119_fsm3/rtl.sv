module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic in,
    output logic out
);

    // State definitions
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State registers
    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic for state transition
    // Asynchronous reset is positive edge triggered
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_A;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        state_next = state; // Default value
        case (state) 
            STATE_A: begin
                if (in == 1'b0) state_next = STATE_A;
                else           state_next = STATE_B;
            end
            STATE_B: begin
                if (in == 1'b0) state_next = STATE_C;
                else           state_next = STATE_B;
            end
            STATE_C: begin
                if (in == 1'b0) state_next = STATE_A;
                else           state_next = STATE_D;
            end
            STATE_D: begin
                if (in == 1'b0) state_next = STATE_C;
                else           state_next = STATE_B;
            end
            default: state_next = STATE_A;
        endcase
    end

    // Combinational logic for output (Moore machine)
    always @(*) begin
        case (state) 
            STATE_D: out = 1'b1;
            default: out = 1'b0;
        endcase
    end

endmodule