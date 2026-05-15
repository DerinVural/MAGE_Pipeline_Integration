 `timescale 1 ps/1 ps
 `define OK 12
 `define INCORRECT 13
 
 // =========================================================================
 // stimulus_gen (Unchanged from Golden Testbench)
 // =========================================================================
 module stimulus_gen (
   input clk,
   output reg too_cold, too_hot, mode, fan_on,
   output reg[511:0] wavedrom_title,
   output reg wavedrom_enable
 );
 
   // Add two ports to module stimulus_gen:
   //    output [511:0] wavedrom_title
   //    output reg wavedrom_enable
 
   task wavedrom_start(input[511:0] title = "");
   endtask
   
   task wavedrom_stop;
     #1;
   endtask
 
   initial begin
     {too_cold, too_hot, mode, fan_on} <= 4'b0010;
     @(negedge clk);
     wavedrom_start("Winter");
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0010;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0010;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b1010;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b1011;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0010;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0011;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0010;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0110;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b1110;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0111;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b1111;
     @(negedge clk) wavedrom_stop();
 
     {too_cold, too_hot, mode, fan_on} <= 4'b0000;
     @(negedge clk);
     wavedrom_start("Summer");
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0000;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0000;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0100;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0101;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0000;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0001;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b0000;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b1000;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b1100;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b1001;
       @(posedge clk) {too_cold, too_hot, mode, fan_on} <= 4'b1101;
     @(negedge clk) wavedrom_stop();
     
     repeat(200)
       @(posedge clk, negedge clk) {too_cold, too_hot, mode, fan_on} <= $random;
     
     #1 $finish;
   end
   
 endmodule
 
 // =========================================================================
 // Testbench (Improved for comprehensive display and error reporting)
 // =========================================================================
 module tb();
 
   // Structure to hold statistics
   typedef struct packed {
     int errors;
     int errortime;
     int errors_heater;
     int errortime_heater;
     int errors_aircon;
     int errortime_aircon;
     int errors_fan;
     int errortime_fan;
 
     int clocks;
   } stats;
   
   stats stats1;
   
   // Signals from stimulus_gen
   wire[511:0] wavedrom_title;
   wire wavedrom_enable;
   
   // Clock generation
   reg clk=0;
   initial forever
     #5 clk = ~clk;
 
   // Testbench Control Signals
   logic mode;
   logic too_cold;
   logic too_hot;
   logic fan_on;
   logic heater_ref; // Expected
   logic heater_dut; // DUT
   logic aircon_ref; // Expected
   logic aircon_dut; // DUT
   logic fan_ref;   // Expected
   logic fan_dut;   // DUT
 
   // Mismatch detection
   wire tb_match;
   wire tb_mismatch = ~tb_match;
 
   // Variables to capture state at first mismatch
   logic [3:0] inputs_at_mismatch; // {mode, too_cold, too_hot, fan_on}
   logic [2:0] expected_outputs_at_mismatch; // {heater_ref, aircon_ref, fan_ref}
   logic [2:0] actual_outputs_at_mismatch; // {heater_dut, aircon_dut, fan_dut}
   int first_mismatch_time = 0;
 
   // Task to display signals clearly
   task display_signals(string stage_name);
     $display("====================================================================");
     $display("!!! FIRST MISMATCH DETECTED at time %0d ps during %s !!!", $time, stage_name);
     $display("--------------------------------------------------------------------");
     // Display inputs (all 1-bit)
     $display("INPUTS: mode=%b, too_cold=%b, too_hot=%b, fan_on=%b", mode, too_cold, too_hot, fan_on);
     // Display expected outputs (all 1-bit)
     $display("EXPECTED OUTPUTS: heater=%b, aircon=%b, fan=%b", heater_ref, aircon_ref, fan_ref);
     // Display actual outputs (all 1-bit)
     $display("ACTUAL OUTPUTS: heater=%b, aircon=%b, fan=%b", heater_dut, aircon_dut, fan_dut);
     $display("====================================================================");
   endtask
 
   initial begin 
     $dumpfile("wave.vcd");
     $dumpvars(0, tb);
   end
 
   // Stimulus Generator Instantiation
   stimulus_gen stim1 (
     .clk, 
     .mode, .too_cold, .too_hot, .fan_on,
     .wavedrom_title, .wavedrom_enable 
   );
 
   // Golden Reference Module Instantiation
   RefModule good1 (
     .mode, .too_cold, .too_hot, .fan_on,
     .heater(heater_ref),
     .aircon(aircon_ref),
     .fan(fan_ref) 
   );
 
   // DUT Instantiation
   TopModule top_module1 (
     .mode, .too_cold, .too_hot, .fan_on,
     .heater(heater_dut),
     .aircon(aircon_dut),
     .fan(fan_dut) 
   );
 
   // --- Verification Logic ---
   // Comparison: {ref} === {dut}
   assign tb_match = ( { heater_ref, aircon_ref, fan_ref } === { heater_dut, aircon_dut, fan_dut } );
 
   // Clocked Logic for State Checking and Error Counting
   always @(posedge clk)
   begin
     // Check state stability after potential input changes (Rising Edge Detection)
     if (clk == 1'b1 && $past(clk) == 1'b0) begin
       stats1.clocks++;
 
       if (!tb_match) begin
         // --- Error Tracking (Original Logic Maintained) ---
         if (stats1.errors == 0) stats1.errortime = $time;
         stats1.errors++;
 
         // Check individual signal errors
         if (heater_ref !== heater_dut) begin
           if (stats1.errors_heater == 0) stats1.errortime_heater = $time;
           stats1.errors_heater = stats1.errors_heater+1'b1; 
         end
         if (aircon_ref !== aircon_dut) begin
           if (stats1.errors_aircon == 0) stats1.errortime_aircon = $time;
           stats1.errors_aircon = stats1.errors_aircon+1'b1; 
         end
         if (fan_ref !== fan_dut) begin
           if (stats1.errors_fan == 0) stats1.errortime_fan = $time;
           stats1.errors_fan = stats1.errors_fan+1'b1; 
         end
 
         // --- New Requirement: Capture state at FIRST mismatch ---
         if (stats1.errors == 1 && first_mismatch_time == 0) begin
           first_mismatch_time = $time;
           inputs_at_mismatch = {mode, too_cold, too_hot, fan_on};
           expected_outputs_at_mismatch = {heater_ref, aircon_ref, fan_ref};
           actual_outputs_at_mismatch = {heater_dut, aircon_dut, fan_dut};
           
           // Display details immediately upon first mismatch detection
           display_signals("First Mismatch Period");
         end
       end
     end
   end
 
   // Final Display Logic (Improved as per requirements)
   final begin
     if (stats1.errors == 0) begin
       $display("\n========================================\nSIMULATION PASSED\n========================================");
     end else begin
       $display("\n========================================\nSIMULATION FAILED - %0d MISMATCHES DETECTED, FIRST AT TIME %0d", stats1.errors, stats1.errortime);
       
       // Display details of the first mismatch (Ensuring compliance if the immediate display failed for some reason)
       if (first_mismatch_time > 0) begin
         $display("--- Details of First Mismatch (Fallback Display) ---");
         // Displaying in binary format as required for 1-bit signals
         $display("Inputs: mode=%b, too_cold=%b, too_hot=%b, fan_on=%b", inputs_at_mismatch[0], inputs_at_mismatch[1], inputs_at_mismatch[2], inputs_at_mismatch[3]);
         $display("Expected Outputs: heater=%b, aircon=%b, fan=%b", expected_outputs_at_mismatch[0], expected_outputs_at_mismatch[1], expected_outputs_at_mismatch[2]);
         $display("Actual Outputs: heater=%b, aircon=%b, fan=%b", actual_outputs_at_mismatch[0], actual_outputs_at_mismatch[1], actual_outputs_at_mismatch[2]);
         $display("---------------------------------------------------");
       end
 
       // Retain original hints for detailed debugging
       if (stats1.errors_heater) $display("Hint: Output 'heater' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_heater, stats1.errortime_heater);
       if (stats1.errors_aircon) $display("Hint: Output 'aircon' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_aircon, stats1.errortime_aircon);
       if (stats1.errors_fan) $display("Hint: Output 'fan' has %0d mismatches. First mismatch occurred at time %0d.", stats1.errors_fan, stats1.errortime_fan);
       
       $display("Total mismatched samples is %1d out of %1d samples\n", stats1.errors, stats1.clocks);
     end
     $display("Simulation finished at %0d ps", $time);
   end
 
   // add timeout after 100K cycles
   initial begin
     #1000000
     $display("TIMEOUT");
     $finish();
   end
 
 endmodule