module TopModule(
    input  logic clk,
    input  logic reset,
    output logic shift_ena
);

    // State definitions
    localparam STATE_IDLE  = 2'b00;
    localparam STATE_COUNT = 2'b01;
    localparam STATE_DONE  = 2'b10;

    logic [1:0] state;
    logic [1:0] count;

    // Initialize signals to avoid X in simulation
    initial begin
        state = STATE_IDLE;
        count = 2'b00;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_COUNT;
            count <= 2'b00;
        end else begin
            case (state)
                STATE_IDLE:
                    state <= STATE_IDLE;

                STATE_COUNT:
                    if (count == 2'd3) begin
                        state <= STATE_DONE;
                        count <= 2'b00;
                    end else begin
                        count <= count + 1'b1;
                    end

                STATE_DONE:
                    state <= STATE_DONE;

                default:
                    state <= STATE_IDLE;
            endcase
        end
    end

    // Combinational output logic
    always @(*) begin
        if (state == STATE_COUNT) begin
            shift_ena = 1'b1;
        end else begin
            shift_ena = 1'b0;
        end
    end

endmodule