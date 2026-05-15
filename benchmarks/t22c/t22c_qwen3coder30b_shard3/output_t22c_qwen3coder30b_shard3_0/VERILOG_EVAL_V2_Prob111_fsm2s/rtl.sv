module TopModule(
    input logic clk,
    input logic reset,
    input logic j,
    input logic k,
    output logic out
);

    // Define states
    localparam OFF = 1'b0;
    localparam ON = 1'b1;

    // State register
    logic state;
    logic state_next;

    // State transition logic
    always @(posedge clk, negedge reset) begin
        if (!reset)
            state <= OFF;
        else
            state <= state_next;
    end

    // Next state logic
    always @(*) begin
        case ({j, k})
            2'b00: state_next = state;
            2'b01: state_next = ON;
            2'b10: state_next = state;
            2'b11: state_next = OFF;
        endcase
    end

    // Output logic (Moore machine)
    always @(*) begin
        case (state)
            OFF: out = 1'b0;
            ON: out = 1'b1;
        endcase
    end

endmodule