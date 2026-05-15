module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic z
);

    // Define the state constants using localparam
    localparam STATE_000 = 3'b000;
    localparam STATE_001 = 3'b001;
    localparam STATE_010 = 3'b010;
    localparam STATE_011 = 3'b011;

    // Register to store the current state
    logic [2:0] state, next_state;

    // Initialize the state register to a known value
    initial state = STATE_000;

    // Sequential block to update the state on the positive edge of the clock
    always @(posedge clk) begin
        if (reset)
            state <= STATE_000;
        else
            state <= next_state;
    end

    // Combinational block to determine the next state and output
    always @(*) begin
        case (state)
            STATE_000: begin
                next_state = x ? STATE_001 : STATE_000;
                z = 0;
            end
            STATE_001: begin
                next_state = (x && state == STATE_001) ? STATE_010 : STATE_001;
                z = 0;
            end
            STATE_010: begin
                next_state = x ? STATE_001 : STATE_010;
                z = 0;
            end
            STATE_011: begin
                next_state = x ? STATE_010 : STATE_001;
                z = 1;
            end
        endcase
    end

endmodule;