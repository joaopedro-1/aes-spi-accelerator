`timescale 1ns/1ps
// AddRoundKey do AES (FIPS-197, 5.1.4): estado XOR chave da rodada
module add_round_key (
  input  logic [127:0] state_i,
  input  logic [127:0] key_i,
  output logic [127:0] state_o
);
  assign state_o = state_i ^ key_i;
endmodule
