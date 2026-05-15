module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic disc,
    output logic flag,
    output logic err
);

    // State encoding
    localparam S_0    = 4'd0;
    localparam S_1    = 4'd1;
    localparam S_2    = 4'd2;
    localparam S_3    = 4'd3;
    localparam S_4    = 4'd4;
    localparam S_5    = 4'd5;
    localparam S_6    = 4'd6;
    localparam S_DISC = 4'd7;
    localparam S_FLAG = 4'd8;
    localparam S_ERR  = 4'd9;

    logic [3:0] state;
    logic [3:0] state_next;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= S_0;
        end else begin
            state <= state_next;
        end
    end

    // Next state combinational logic
    always @(*) begin
        state_next = S_0;
        case (state)
            S_0:
                if (in) state_next = S_1;
                else    state_next = S_0;
            S_1:
                if (in) state_next = S_2;
                else    state_next = S_0;
            S_2:
                if (in) state_next = S_3;
                else    state_next = S_0;
            S_3:
                if (in) state_next = S_4;
                else    state_next = S_0;
            S_4:
                if (in) state_next = S_5;
                else    state_next = S_0;
            S_5:
                if (in) state_next = S_6;
                else    state_next = S_DISC;
            S_6:
                if (in) state_next = S_ERR;
                else    state_next = S_FLAG;
            S_DISC:
                state_next = S_0;
            S_FLAG:
                state_next = S_0;
            S_ERR:
                if (in) state_next = S_ERR;
                else    state_next = S_0;
            default:
                state_next = S_0;
        endcase
    end

    // Output combinational logic (Moore Machine)
    always @(*) begin
        disc = 1'b0;
        flag = 1'b0;
        err  = 1'b0;
        case (state)
            S_DISC:
                disc = 1'b1;
            S_FLAG:
                flag = 1'b1;
            S_ERR:
                err  = 1'b1;
            default:
                begin
                    disc = 1'b0;
                    flag = 1'b0;
                    err  = 1'b0;
                end
        endcase
    end

endmodule