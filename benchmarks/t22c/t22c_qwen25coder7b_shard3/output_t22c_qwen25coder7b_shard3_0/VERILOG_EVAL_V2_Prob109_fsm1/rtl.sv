module TopModule (
    input logic clk,
    input logic areset,
    input logic in,
    output logic out,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    // Define states using localparam
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;

    // Register to hold the current state
    logic [1:0] state;
    logic [1:0] state_next;

    // Initialize the state to STATE_B
    initial begin
        state = STATE_B;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (areset)
            state <= STATE_B;
        else
            state <= state_next;
    end

    // Combinational logic to determine the next state
    always @(*) begin
        state_next = state;
        case (state)
        STATE_A:
            state_next = (in) ? STATE_A : STATE_B;
        STATE_B:
            state_next = (in) ? STATE_B : STATE_A;
        endcase
    end

    // Combinational logic to determine the output
    always @(*) begin
        out = (state == STATE_A);
    end

    // Set wavedrom properties
    assign wavedrom_title = "Moore Machine";
    assign wavedrom_enable = 1;

endmodule;