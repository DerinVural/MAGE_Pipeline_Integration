module TopModule(clk, areset, areset_n, x, z);
    input logic clk;
    input logic areset;
    input logic areset_n;
    input logic x;
    output logic z;

    // Define states
    localparam STATE_A = 2'b01;
    localparam STATE_B = 2'b10;

    // State register
    logic [1:0] state;

    // Initial state
    initial begin
        state = STATE_A;
    end

    // Always block for updating state
    always @(posedge clk or negedge areset_n) begin
        if (areset_n == 0)
            state <= STATE_A;
        else begin
            case (state)
                STATE_A: state <= (x == 1'b0) ? STATE_A : STATE_B;
                STATE_B: state <= (x == 1'b0) ? STATE_B : STATE_A;
                default: state <= STATE_A;
            endcase
        end
    end

    // Output logic
    always @(*) begin
        z = (state == STATE_A) ? 1'b0 : 1'b1;
    end
endmodule