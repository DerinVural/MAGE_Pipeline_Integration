module TopModule (
    input logic clk,
    input logic x,
    input logic [2:0] y,
    output logic Y0,
    output logic z
);

    // Define states
    localparam STATE_A = 3'b000;
    localparam STATE_B = 3'b001;
    localparam STATE_C = 3'b010;
    localparam STATE_D = 3'b011;
    localparam STATE_E = 3'b100;

    // State register
    logic [2:0] state;
    logic [2:0] state_next;

    // Initialize state register
    initial begin
        state = STATE_A;
    end

    // Always block for state update
    always @(posedge clk) begin
        state <= state_next;
    end

    // Next state logic
    always @(*) begin
        case ({state, x, y})
            STATE_A: state_next = (y == 3'b000 || y == 3'b001) ? STATE_B : STATE_A;
            STATE_B: state_next = (y == 3'b001 || y == 3'b100) ? STATE_C : STATE_A;
            STATE_C: state_next = (y == 3'b010 || y == 3'b001) ? STATE_B : STATE_A;
            STATE_D: state_next = (y == 3'b001 || y == 3'b010) ? STATE_C : STATE_A;
            STATE_E: state_next = (y == 3'b011 || y == 1'b0) ? STATE_C : STATE_A;
        endcase
    end

    // Output logic
    always @(*) begin
        Y0 = (state == STATE_D || state == STATE_E) ? 1'b1 : 1'b0;
        z = (state == STATE_D || state == STATE_E) ? 1'b1 : 1'b0;
    end

endmodule