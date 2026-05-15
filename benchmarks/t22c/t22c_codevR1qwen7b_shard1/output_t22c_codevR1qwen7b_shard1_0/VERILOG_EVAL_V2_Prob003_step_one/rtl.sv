module stimulus_gen (input clk, output logic [511:0] wavedrom_title, output logic wavedrom_enable); 
  // Convert ASCII string to 512 bits: 'Output should be 1' padded to 512 bits
  assign wavedrom_title = 512'h4F75747065722073686563652062652031; // ASCII for 'Output should be 1' followed by zeros
  assign wavedrom_enable = 1'b1;
endmodule