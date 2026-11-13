`timescale 1ns/1ps
// AddRoundKey (FIPS-197 5.1.4): state ^ chave da rodada. Serve tambem na decifra.
module minisoc_aes_add_round_key (
  input  logic [127:0] state_i,
  input  logic [127:0] key_i,
  output logic [127:0] state_o
);

  assign state_o = state_i ^ key_i;

endmodule
