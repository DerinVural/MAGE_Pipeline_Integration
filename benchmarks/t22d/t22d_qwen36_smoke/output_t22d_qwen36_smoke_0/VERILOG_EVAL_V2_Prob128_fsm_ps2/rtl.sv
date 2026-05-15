module TopModule (
    input logic clk,
    input logic reset,
    input logic [7:0] in,
    output logic done
);

    localparam IDLE = 2'b00;
    localparam GOT1 = 2'b01;
    localparam GOT2 = 2'b10;
    localparam GOT3 = 2'b11;

    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic for state register
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= state_next;
    end

    // Combinational next state logic
    always @(*) begin
        state_next = state;
        case (state)
            IDLE: begin
                if (in[3])
                    state_next = GOT1;
                else
                    state_next = IDLE;
            end
            GOT1: state_next = GOT2;
            GOT2: state_next = GOT3;
            GOT3: state_next = IDLE;
        endcase
    end

    // Combinational output logic
    always @(*) begin
        case (state)
            GOT3: done = 1'b1;
            default: done = 1'b0;
        endcase
    end

endmodule