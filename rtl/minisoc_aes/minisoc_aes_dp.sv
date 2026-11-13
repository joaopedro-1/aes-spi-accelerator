`timescale 1ns/1ps
// Datapath AES-128 iterativo, uma rodada por ciclo.
// start: state = bloco ^ K0 (ou K10 na decifra). Depois 10 rodadas, a ultima sem MixColumns.
// A chave vem de fora: o dp pede o indice em rnd_o e recebe em rk_i.
module minisoc_aes_dp (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         start_i,
  input  logic         decrypt_i,
  input  logic [127:0] block_i,
  input  logic [127:0] rk_i,
  output logic [3:0]   rnd_o,
  output logic [127:0] block_o,
  output logic         busy_o,
  output logic         done_o
);

  logic [127:0] state_q;
  logic [3:0]   rnd_q;   // 1..10
  logic         dec_q, busy_q, done_q;
  logic         last;

  assign last = (rnd_q == 4'd10);

  // cifra: SubBytes, ShiftRows, MixColumns, AddRoundKey
  logic [127:0] sub, shift, mix, enc_next;

  minisoc_aes_sub_bytes   u_sub   (.state_i(state_q), .state_o(sub));
  minisoc_aes_shift_rows  u_shift (.state_i(sub),     .state_o(shift));
  minisoc_aes_mix_columns u_mix   (.state_i(shift),   .state_o(mix));

  assign enc_next = (last ? shift : mix) ^ rk_i;

  // decifra (FIPS-197 5.3): InvShiftRows, InvSubBytes, AddRoundKey, InvMixColumns
  logic [127:0] inv_shift, inv_sub, inv_ark, inv_mix, dec_next;

  minisoc_aes_inv_shift_rows  u_inv_shift (.state_i(state_q),   .state_o(inv_shift));
  minisoc_aes_inv_sub_bytes   u_inv_sub   (.state_i(inv_shift), .state_o(inv_sub));
  minisoc_aes_inv_mix_columns u_inv_mix   (.state_i(inv_ark),   .state_o(inv_mix));

  assign inv_ark  = inv_sub ^ rk_i;
  assign dec_next = last ? inv_ark : inv_mix;

  // parado ja aponta para a chave do start
  always_comb begin
    if (!busy_q)    rnd_o = decrypt_i ? 4'd10 : 4'd0;
    else if (dec_q) rnd_o = 4'd10 - rnd_q;
    else            rnd_o = rnd_q;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rnd_q  <= '0;
      dec_q  <= 1'b0;
      busy_q <= 1'b0;
      done_q <= 1'b0;
    end else begin
      done_q <= busy_q && last;
      if (start_i && !busy_q) begin
        rnd_q  <= 4'd1;
        dec_q  <= decrypt_i;
        busy_q <= 1'b1;
      end else if (busy_q) begin
        rnd_q <= rnd_q + 4'd1;
        if (last) busy_q <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (start_i && !busy_q) state_q <= block_i ^ rk_i;
    else if (busy_q)        state_q <= dec_q ? dec_next : enc_next;
  end

  assign block_o = state_q;
  assign busy_o  = busy_q;
  assign done_o  = done_q;

endmodule
