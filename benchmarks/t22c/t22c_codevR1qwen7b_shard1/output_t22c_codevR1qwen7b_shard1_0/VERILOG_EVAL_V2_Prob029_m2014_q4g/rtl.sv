module TopModule (input in1, in2, in3, output out); 
 logic xnor_result; 
 assign xnor_result = ~(~in1 ^ ~in2); 
 assign out = xnor_result ^ in3; 
endmodule