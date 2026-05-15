module TopModule (
    input  logic clk,
    input  logic reset,
    output logic shift_ena
);

    // State definitions
    localparam STATE_COUNTING = 2'b01;
    localparam STATE_DISABLED = 2'b10;

    // State and counter registers
    logic [1:0] state;
    logic [2:0] count;

    // Initialize signals to avoid X
    initial begin
        state = 2'b00;
        count = 3'b000;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            // On reset, start the 4-cycle sequence
            state <= STATE_COUNTING;
            count <= 3'd1;
        end else begin
            case (state)
                STATE_COUNTING:
                    if (count == 3'd4) begin
                        state <= STATE_DISABLED;
                        count <= 3'd0;
                    end else begin
                        count <= count + 3'd1;
                    end
                
                STATE_DISABLED:
                    state <= STATE_DISABLED;

                default:
                    state <= STATE_DISABLED;
            endcase
        end
    end

    // Combinational output logic
    always @(*)
        if (state == STATE_COUNTING) begin
            shift_ena = 1'b1;
        end else begin
            shift_ena = 1'b0;
        end

endmodule