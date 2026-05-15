module TopModule(
    input  logic clk,
    input  logic reset,
    output logic shift_ena
);

    // Define states using localparam
    localparam IDLE      = 2'b00;
    localparam ENABLE_1  = 2'b01;
    localparam ENABLE_2  = 2'b10;
    localparam ENABLE_3  = 2'b11;

    // State register
    logic [1:0] current_state, next_state;

    // Sequential logic for state transition
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= ENABLE_1;
        else
            current_state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            ENABLE_1: next_state = ENABLE_2;
            ENABLE_2: next_state = ENABLE_3;
            ENABLE_3: next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end

    // Output logic
    assign shift_ena = (current_state != IDLE);

endmodule