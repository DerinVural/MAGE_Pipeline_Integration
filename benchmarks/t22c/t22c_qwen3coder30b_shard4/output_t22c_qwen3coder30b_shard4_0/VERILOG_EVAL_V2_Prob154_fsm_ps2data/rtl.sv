module TopModule (
    input clk,
    input reset,
    input [7:0] in,
    output reg [23:0] out_bytes,
    output reg done
);

    // Define states
    localparam IDLE   = 2'b00;
    localparam BYTE1  = 2'b01;
    localparam BYTE2  = 2'b10;
    localparam BYTE3  = 2'b11;

    // State register
    reg [1:0] state;
    reg [1:0] state_next;

    // Register to hold the three bytes
    reg [7:0] byte1;
    reg [7:0] byte2;
    reg [7:0] byte3;

    // Initialize the registers to known values
    initial begin
        state <= IDLE;
        byte1 <= 8'h00;
        byte2 <= 8'h00;
        byte3 <= 8'h00;
    end

    // Sequential logic for state and byte storage
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            byte1 <= 8'h00;
            byte2 <= 8'h00;
            byte3 <= 8'h00;
        end else begin
            state <= state_next;
            if (state == IDLE) begin
                byte1 <= in;
            end else if (state == BYTE1) begin
                byte2 <= in;
            end else if (state == BYTE2) begin
                byte3 <= in;
            end
        end
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (in[3])
                    state_next = BYTE1;
                else
                    state_next = IDLE;
            end
            BYTE1: state_next = BYTE2;
            BYTE2: state_next = BYTE3;
            BYTE3: state_next = IDLE;
            default: state_next = IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        case (state)
            BYTE3: begin
                out_bytes = {byte1, byte2, byte3};
                done = 1'b1;
            end
            default: begin
                done = 1'b0;
            end
        endcase
    end

endmodule