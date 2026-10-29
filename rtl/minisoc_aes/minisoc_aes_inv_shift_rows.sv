`timescale 1ns/1ps
// InvShiftRows (FIPS-197, 5.3.1): a linha r gira r bytes para a direita, desfazendo o ShiftRows.
//
//   s[0] s[4] s[8]  s[12]        s[0]  s[4]  s[8]  s[12]
//   s[1] s[5] s[9]  s[13]   ->   s[13] s[1]  s[5]  s[9]
//   s[2] s[6] s[10] s[14]        s[10] s[14] s[2]  s[6]
//   s[3] s[7] s[11] s[15]        s[7]  s[11] s[15] s[3]
module minisoc_aes_inv_shift_rows (
  input  logic [127:0] state_i,
  output logic [127:0] state_o
);

  logic [7:0] s [16];

  for (genvar i = 0; i < 16; i++) begin : gen_bytes
    assign s[i] = state_i[127-8*i -: 8];
  end

  assign state_o = {s[0],  s[13], s[10], s[7],    // coluna 0
                    s[4],  s[1],  s[14], s[11],   // coluna 1
                    s[8],  s[5],  s[2],  s[15],   // coluna 2
                    s[12], s[9],  s[6],  s[3]};   // coluna 3

endmodule
