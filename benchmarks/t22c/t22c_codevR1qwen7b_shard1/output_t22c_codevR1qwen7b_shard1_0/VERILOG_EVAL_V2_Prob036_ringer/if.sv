module stimulus_gen (input clk, output reg ring, vibrate_mode);
    output [511:0] wavedrom_title;
    output wavedrom_enable;
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
endmodule

module tb();
    reg clk=0;
    reg ring, vibrate_mode;
    reg ringer_ref, motor_ref;
    reg ringer_dut, motor_dut;
    wire tb_mismatch;
    TopModule top_module1 ( .ring(ring), .vibrate_mode(vibrate_mode), .ringer(ringer_dut), .motor(motor_dut) );
    RefModule ref_module1 ( .ring(ring), .vibrate_mode(vibrate_mode), .ringer(ringer_ref), .motor(motor_ref) );
endmodule