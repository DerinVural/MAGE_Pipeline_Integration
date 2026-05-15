```SystemVerilog
module TopModule (
    input  logic clk,
    input  logic in,
    input  logic reset,
    output logic [7:0] out_byte,
    output logic done
);
endmodule
```
The IO interface matches the golden testbench and is based on the original input_spec. All ports are declared as logic, as required.