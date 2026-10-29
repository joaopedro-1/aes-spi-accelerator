`timescale 1ns/1ps
// InvSubBytes (FIPS-197, 5.3.2): uma S-box inversa para cada um dos 16 bytes do estado.
module minisoc_aes_inv_sub_bytes (
  input  logic [127:0] state_i,
  output logic [127:0] state_o
);

  // Byte i do estado em [127-8i -: 8]: byte 0 = [127:120], byte 15 = [7:0]
  for (genvar i = 0; i < 16; i++) begin : gen_inv_sbox
    minisoc_aes_inv_sbox u_inv_sbox (
      .data_i (state_i[127-8*i -: 8]),
      .data_o (state_o[127-8*i -: 8])
    );
  end

endmodule
