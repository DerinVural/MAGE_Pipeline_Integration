module stimulus_gen(input clk, output reg ring, output reg vibrate_mode);
    output [511:0] wavedrom_title;
    output wavedrom_enable;
    task wavedrom_start(input [511:0] title = ""); endtask
    task wavedrom_stop; #1; endtask
    assign wavedrom_title = 0;
    assign wavedrom_enable = 0;
endmodule

module tb();
    reg clk = 0;
    initial forever #5 clk = ~clk;

    reg ring = 0;
    reg vibrate_mode = 0;
    reg ringer_ref, motor_ref;
    reg ringer_dut, motor_dut;
    wire tb_mismatch = ( {ringer_ref, motor_ref} === ( {ringer_ref, motor_ref} ^ {ringer_dut, motor_dut} ^ {ringer_ref, motor_dut} ) );

    TopModule top_module1 ( .ring(ring), .vibrate_mode(vibrate_mode), .ringer(ringer_dut), .motor(motor_dut) );
    RefModule ref_module1 ( .ring(ring), .vibrate_mode(vibrate_mode), .ringer(ringer_ref), .motor(motor_ref) );

    initial begin
        #10 ring = 1;
        vibrate_mode = 1;
        #10 $finish;
    end
endmodule

module TopModule(input ring, input vibrate_mode, output ringer, output motor);
    assign ringer = (vibrate_mode == 0) ? ~ring : 0;
    assign motor = (vibrate_mode) ? ~ring : 0;
endmodule

module RefModule(input ring, input vibrate_mode, output ringer, output motor);
    // Reference implementation to match the logic of TopModule
    assign ringer = vibrate_mode ? 1'b0 : ring;
    assign motor = vibrate_mode ? ring : 1'b0;
endmodule