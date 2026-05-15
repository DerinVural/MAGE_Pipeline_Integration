module TopModule (
    input clk,
    input reset,
    input ena,
    output pm,
    output [7:0] hh,
    output [7:0] mm,
    output [7:0] ss
);

    // Internal signals
    logic [7:0] hh_reg;
    logic [7:0] mm_reg;
    logic [7:0] ss_reg;
    logic pm_reg;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            hh_reg <= 8'h12;
            mm_reg <= 8'h00;
            ss_reg <= 8'h00;
            pm_reg <= 1'b0;
        end
        else if (ena) begin
            // Increment seconds
            if (ss_reg == 8'h59) begin
                ss_reg <= 8'h00;
                // Increment minutes
                if (mm_reg == 8'h59) begin
                    mm_reg <= 8'h00;
                    // Increment hours
                    if (hh_reg == 8'h12) begin
                        hh_reg <= 8'h1;
                        pm_reg <= ~pm_reg; // Toggle AM/PM
                    end
                    else begin
                        hh_reg <= hh_reg + 1;
                    end
                end
                else begin
                    mm_reg <= mm_reg + 1;
                end
            end
            else begin
                ss_reg <= ss_reg + 1;
            end
        end
    end

    // Assign outputs
    assign pm = pm_reg;
    assign hh = hh_reg;
    assign mm = mm_reg;
    assign ss = ss_reg;

endmodule