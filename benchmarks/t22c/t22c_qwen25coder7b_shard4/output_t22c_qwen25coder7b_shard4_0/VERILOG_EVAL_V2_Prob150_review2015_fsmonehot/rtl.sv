module TopModule (
    logic d,
    logic done_counting,
    logic ack,
    logic [9:0] state,
    logic B3_next,
    logic S_next,
    logic S1_next,
    logic Count_next,
    logic Wait_next,
    logic done,
    logic counting,
    logic shift_ena
);

// Initialize the state register to a known value
logic [9:0] current_state;
initial begin
current_state = 10'b0000000001;
end

// Combinational logic to determine the next state
always @(*) begin
    logic [9:0] next_state = state;
    logic shift_ena_next = 0;
    logic counting_next = 0;
    logic done_next = 0;

    case (current_state)
        10'b0000000001: next_state = (d == 1'b0) ? 10'b0000000001 : 10'b0000000010;
        10'b0000000010: next_state = (d == 1'b0) ? 10'b0000000010 : 10'b0000000100;
        10'b0000000100: next_state = (d == 1'b0) ? 10'b0000000100 : 10'b0000000100;
        10'b0000000100: next_state = (d == 1'b1) ? 10'b0000000100 : 10'b0000000110;
        10'b0000000100: next_state = (d == 1'b0) ? 10'b0000000100 : 10'b0000000110;
        10'b0000000110: next_state = (d == 1'b1) ? 10'b0000000110 : 10'b0000000110;
        10'b0000001110: next_state = (d == 1'b0) ? 10'b0000001110 : 10'b0000000001;
        10'b0000001110: next_state = (d == 1'b1) ? 10'b0000001110 : 10'b0000001000;
        10'b0000001000: shift_ena_next = 1;
        10'b0000010000: shift_ena_next = 1;
        10'b0000100000: shift_ena_next = 1;
        10'b0001000000: counting_next = 1;
        10'b0010000000: counting_next = 1;
        10'b0100000000: done_next = 1;
    endcase

    // Assign the next-state logic to the flip-flops
    B3_next = (next_state == 10'b0000001000);
    S_next = (next_state == 10'b0000000001);
    S1_next = (next_state == 10'b0000000010);
    Count_next = (next_state == 10'b0001000000);
    Wait_next = (next_state == 10'b0100000000);
    done = done_next;
    counting = counting_next;
    shift_ena = shift_ena_next;
end

// Sequential logic to update the state register
always @(posedge clk or posedge reset) begin
    if (reset)
        current_state <= 10'b0000000001;
    else
        current_state <= next_state;
end

endmodule