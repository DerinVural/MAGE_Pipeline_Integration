module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic ena,
    output logic pm,
    output logic [7:0] hh,
    output logic [7:0] mm,
    output logic [7:0] ss
);

    // Internal registers for counting
    logic [5:0] h_cnt;
    logic [5:0] m_cnt;
    logic [5:0] s_cnt;
    logic       p_cnt;

    // Sequential logic for the clock counters
    always @(posedge clk) begin
        if (reset) begin
            h_cnt <= 6'd12;
            m_cnt <= 6'd0;
            s_cnt <= 6'd0;
            p_cnt <= 1'b0;
        end else if (ena) begin
            if (s_cnt == 6'd59) begin
                s_cnt <= 6'd0;
                if (m_cnt == 6'd59) begin
                    m_cnt <= 6'd0;
                    if (h_cnt == 6'd12) begin
                        h_cnt <= 6'd1;
                        // 12:59:59 -> 01:00:00. PM does not toggle.
                    end else if (h_cnt == 6'd11) begin
                        h_cnt <= 6'd12;
                        p_cnt <= ~p_cnt; // 11:59:59 -> 12:00:00 toggles PM
                    end else begin
                        h_cnt <= h_cnt + 6'd1;
                    end
                end else begin
                    m_cnt <= m_cnt + 6'd1;
                end
            end else begin
                s_cnt <= s_cnt + 6'd1;
            end
        end
    end

    // Combinational logic for BCD output conversion
    always @(*) begin
        // Seconds BCD
        ss[3:0] = s_cnt % 10;
        ss[7:4] = s_cnt / 10;

        // Minutes BCD
        mm[3:0] = m_cnt % 10;
        mm[7:4] = m_cnt / 10;

        // Hours BCD
        hh[3:0] = h_cnt % 10;
        hh[7:4] = h_cnt / 10;

        // PM output
        pm = p_cnt;
    end

endmodule