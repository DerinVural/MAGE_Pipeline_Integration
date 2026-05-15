module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic ena,
    output logic pm,
    output logic [7:0] hh,
    output logic [7:0] mm,
    output logic [7:0] ss
);

    // BCD digits for seconds
    logic [3:0] ss_tens, ss_units;
    // BCD digits for minutes
    logic [3:0] mm_tens, mm_units;
    // BCD digits for hours
    logic [3:0] hh_tens, hh_units;

    // Initialize values to avoid X in simulation
    initial begin
        ss_tens = 4'd0;
        ss_units = 4'd0;
        mm_tens = 4'd0;
        mm_units = 4'd0;
        hh_tens = 4'd1;
        hh_units = 4'd2;
        pm = 1'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            // Reset to 12:00:00 AM
            ss_tens <= 4'd0;
            ss_units <= 4'd0;
            mm_tens <= 4'd0;
            mm_units <= 4'd0;
            hh_tens <= 4'd1;
            hh_units <= 4'd2;
            pm <= 1'b0;
        end else if (ena) begin
            // Seconds logic
            if (ss_units == 4'd9) begin
                if (ss_tens == 4'd5) begin
                    // Seconds rollover
                    ss_tens <= 4'd0;
                    ss_units <= 4'd0;
                    
                    // Minutes logic
                    if (mm_units == 4'd9) begin
                        if (mm_tens == 4'd5) begin
                            // Minutes rollover
                            mm_tens <= 4'd0;
                            mm_units <= 4'd0;

                            // Hours logic
                            if (hh_tens == 4'd1 && hh_units == 4'd2) begin
                                // 12:59:59 -> 01:00:00
                                hh_tens <= 4'd0;
                                hh_units <= 4'd1;
                                // PM toggle: 12:59:59 AM -> 01:00:00 AM (no change), 
                                // 12:59:59 PM -> 01:00:00 PM (no change). 
                                // Wait, the rule for PM is: 12:00:00 is PM if it's PM.
                                // Let's refine the PM toggle logic.
                            end else if (hh_tens == 4'd1 && hh_units == 4'd1) begin
                                // 11:59:59 -> 12:00:00
                                hh_tens <= 4'd1;
                                hh_units <= 4'd2;
                                pm <= ~pm; // Toggle PM when moving from 11 to 12
                            end else begin
                                // Standard increment 01->02, etc.
                                if (hh_units == 4'd9) begin
                                    hh_tens <= hh_tens + 1'b1;
                                    hh_units <= 4'd0;
                                end else begin
                                    hh_units <= hh_units + 1'b1;
                                end
                            end
                        end else begin
                            mm_tens <= mm_tens + 1'b1;
                            mm_units <= 4'd0;
                        end
                    end else begin
                        if (mm_units == 4'd9) begin
                            mm_tens <= mm_tens + 1'b1;
                            mm_units <= 4'd0;
                        end else begin
                            mm_units <= mm_units + 1'b1;
                        end
                    end
                end else begin
                    ss_tens <= ss_tens + 1'b1;
                    ss_units <= 4'd0;
                end
            end else begin
                ss_units <= ss_units + 1'b1;
            end
        end
    end

    // Correction on PM logic: 
    // 12-hour cycle: 12:00:00 AM (pm=0) -> 12:59:59 AM -> 01:00:00 AM (pm=0) ... 
    // -> 11:59:59 AM -> 12:00:00 PM (pm=1) -> 12:59:59 PM -> 01:00:00 PM (pm=1) ...
    // -> 11:59:59 PM -> 12:00:00 AM (pm=0)
    // So PM toggles when HH goes from 11 to 12.
    // Let's rewrite the hour increment logic slightly for clarity.

    // Re-implementing the sequential block to be cleaner and correct
    always @(posedge clk) begin
        if (reset) begin
            ss_tens <= 4'd0;
            ss_units <= 4'd0;
            mm_tens <= 4'd0;
            mm_units <= 4'd0;
            hh_tens <= 4'd1;
            hh_units <= 4'd2;
            pm <= 1'b0;
        end else if (ena) begin
            if (ss_units == 4'd9 && ss_tens == 4'd5) begin
                // Second rollover
                if (mm_units == 4'd9 && mm_tens == 4'd5) begin
                    // Minute rollover
                    if (hh_tens == 4'd1 && hh_units == 4'd2) begin
                        // 12 -> 01
                        hh_tens <= 4'd0;
                        hh_units <= 4'd1;
                        // PM does NOT toggle here (12:59:59 AM/PM -> 01:00:00 AM/PM)
                    end else if (hh_tens == 4'd1 && hh_units == 4'd1) begin
                        // 11 -> 12
                        hh_tens <= 4'd1;
                        hh_units <= 4'd2;
                        pm <= ~pm; // Toggle PM
                    end else begin
                        // 01 -> 02, ..., 10 -> 11
                        if (hh_units == 4'd9) begin
                            hh_tens <= hh_tens + 1'b1;
                            hh_units <= 4'd0;
                        end else begin
                            hh_units <= hh_units + 1'b1;
                        end
                    end
                    mm_tens <= 4'd0;
                    mm_units <= 4'd0;
                end else begin
                    // Minute increment
                    if (mm_units == 4'd9) begin
                        mm_tens <= mm_tens + 1'b1;
                        mm_units <= 4'd0;
                    end else begin
                        mm_units <= mm_units + 1'b1;
                    end
                    ss_tens <= 4'd0;
                    ss_units <= 4'd0;
                end
            end else begin
                // Second increment
                if (ss_units == 4'd9) begin
                    ss_tens <= ss_tens + 1'b1;
                    ss_units <= 4'd0;
                end else begin
                    ss_units <= ss_units + 1'b1;
                end
            end
        end
    end

    // Output assignments
    assign ss = {ss_tens, ss_units};
    assign mm = {mm_tens, mm_units};
    assign hh = {hh_tens, hh_units};

endmodule