module TopModule (input logic clk, input logic reset, input logic slowena, output logic [3:0] q);

    localparam S0 = 4'd0;
    localparam S1 = 4'd1;
    localparam S2 = 4'd2;
    localparam S3 = 4'd3;
    localparam S4 = 4'd4;
    localparam S5 = 4'd5;
    localparam S6 = 4'd6;
    localparam S7 = 4'd7;
    localparam S8 = 4'd8;
    localparam S9 = 4'd9;

    logic [3:0] next_state;

    // Sequential block
    always @(posedge clk) begin
        if (reset) begin
            q <= S0;
        end else if (slowena) begin
            q <= next_state;
        end else begin
            q <= q; // retain state when not enabled
        end
    end

    // Combinational next state
    always @(*) begin
        case (q)
            S0: next_state = S1;
            S1: next_state = S2;
            S2: next_state = S3;
            S3: next_state = S4;
            S4: next_state = S5;
            S5: next_state = S6;
            S6: next_state = S7;
            S7: next_state = S8;
            S8: next_state = S9;
            S9: next_state = S0;
            default: next_state = S0;
        endcase
    end

    // Initial block for initialization
    initial begin
        q = S0;
    end

endmodule