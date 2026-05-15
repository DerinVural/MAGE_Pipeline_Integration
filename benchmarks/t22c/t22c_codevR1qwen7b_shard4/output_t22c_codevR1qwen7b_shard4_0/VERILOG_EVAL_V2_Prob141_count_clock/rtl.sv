module TopModule (input clk, input reset, input ena, output logic pm, output logic [7:0] hh, output logic [7:0] mm, output logic [7:0] ss);

localparam [1:0] S_RESET = 2'b00,
                 S_SEC = 2'b01,
                 S_MIN = 2'b10,
                 S_HR = 2'b11;

reg [1:0] state, next_state;

// Initialize state on reset
initial begin
    state = S_RESET;
end

always @(posedge clk) begin
    if (reset) begin
        state <= S_RESET;
    end else begin
        state <= next_state;
    end
end

// Next state logic
always @(*) begin
    case (state)
        S_RESET: next_state = S_SEC;
        S_SEC: next_state = S_SEC + (ss[3:0] == 4'h9 && ss[7:4] == 4'h5) ? S_MIN : S_SEC;
        S_MIN: next_state = S_MIN + (mm[3:0] == 4'h9 && mm[7:4] == 4'h5) ? S_HR : S_MIN;
        S_HR: next_state = S_HR + (hh == 8'h12 && pm) ? S_RESET : S_HR;
        default: next_state = S_RESET;
    endcase
end

// Seconds counter
always @(posedge clk) begin
    if (reset) begin
        ss <= 8'h00;
    end else if (ena && state == S_SEC) begin
        if (ss[3:0] == 4'h9 && ss[7:4] == 4'h5) begin
            ss <= 8'h00;
        end else begin
            ss <= ss + 1;
        end
    end
end

// Minutes counter
always @(posedge clk) begin
    if (reset) begin
        mm <= 8'h00;
    end else if (state == S_MIN && ena) begin
        if (mm[3:0] == 4'h9 && mm[7:4] == 4'h5) begin
            mm <= 8'h00;
        end else begin
            mm <= mm + 1;
        end
    end
end

// Hours counter and PM toggle
always @(posedge clk) begin
    if (reset) begin
        hh <= 8'h12;
        pm <= 1'b0;
    end else if (state == S_HR && ena) begin
        if (hh == 8'h12 && pm) begin
            hh <= 8'h12;
            pm <= 1'b0;
        end else if (hh == 8'h11) begin
            hh <= pm ? 8'h12 : 8'h1;
            pm <= ~pm;
        end else if (hh == 8'h00) begin
            hh <= 8'h12;
            pm <= 1'b0;
        end else begin
            hh <= hh + 1;
        end
    end
end

endmodule