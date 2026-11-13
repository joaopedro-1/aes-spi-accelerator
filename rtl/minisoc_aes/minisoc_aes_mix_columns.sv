`timescale 1ns/1ps
// MixColumns (FIPS-197 5.1.3). Cada coluna e multiplicada pela matriz
//   02 03 01 01
//   01 02 03 01
//   01 01 02 03
//   03 01 01 02
// com 03.x = 02.x ^ x. A coluna c e state[127-32c -: 32].
module minisoc_aes_mix_columns (
  input  logic [127:0] state_i,
  output logic [127:0] state_o
);

  // multiplica por 02 em GF(2^8)
  function automatic logic [7:0] xtime(logic [7:0] b);
    return {b[6:0], 1'b0} ^ (b[7] ? 8'h1b : 8'h00);
  endfunction

  for (genvar c = 0; c < 4; c++) begin : gen_col
    logic [7:0] s0, s1, s2, s3;

    assign {s0, s1, s2, s3} = state_i[127-32*c -: 32];

    // 02.s0 ^ 03.s1 ^ s2 ^ s3 = 02.(s0^s1) ^ s1 ^ s2 ^ s3
    assign state_o[127-32*c -: 32] = {xtime(s0 ^ s1) ^ s1 ^ s2 ^ s3,
                                      xtime(s1 ^ s2) ^ s2 ^ s3 ^ s0,
                                      xtime(s2 ^ s3) ^ s3 ^ s0 ^ s1,
                                      xtime(s3 ^ s0) ^ s0 ^ s1 ^ s2};
  end

endmodule
