module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic bump_left,
    input  logic bump_right,
    output logic walk_left,
    output logic walk_right
);

    logic state;
    logic state_next;

    // Sequential logic: State register with asynchronous active-high reset
    always @(posedge clk or posedge areset) begin
        if (areset)
            state <= 1'b0;
        else
            state <= state_next;
    end

    // Combinational logic: Next state determination
    always @(*) begin
        if (state == 1'b0)
            state_next = bump_left;
        else
            state_next = ~bump_right;
    end

    // Output logic: Moore machine outputs depend only on current state
    assign walk_left  = ~state;
    assign walk_right = state;

endmodule