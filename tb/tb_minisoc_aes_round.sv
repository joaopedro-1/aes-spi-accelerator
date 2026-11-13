`timescale 1ns/1ps
// TB semana 3: rodadas do AES com os blocos das semanas 2 e 3.
// Compara com os valores intermediarios da FIPS-197, apendice B (cifra) e C.1 (decifra).
module tb_minisoc_aes_round;

  logic [127:0] state, round_key, sub, shift, mix, round_in, next, inv_mix;
  logic [127:0] col_in, col_mix, col_inv;
  logic         last;  // rodada 10 nao tem MixColumns
  int errors = 0;

  minisoc_aes_sub_bytes       u_sub     (.state_i(state), .state_o(sub));
  minisoc_aes_shift_rows      u_shift   (.state_i(sub),   .state_o(shift));
  minisoc_aes_mix_columns     u_mix     (.state_i(shift), .state_o(mix));
  minisoc_aes_add_round_key   u_ark     (.state_i(round_in), .key_i(round_key), .state_o(next));
  minisoc_aes_inv_mix_columns u_inv_mix (.state_i(mix),   .state_o(inv_mix));

  // uma rodada da decifra
  logic [127:0] istate, ikey, ishift, isub, iadd, imix;

  minisoc_aes_inv_shift_rows  u_ishift (.state_i(istate), .state_o(ishift));
  minisoc_aes_inv_sub_bytes   u_isub   (.state_i(ishift), .state_o(isub));
  minisoc_aes_add_round_key   u_iadd   (.state_i(isub),   .key_i(ikey), .state_o(iadd));
  minisoc_aes_inv_mix_columns u_imix   (.state_i(iadd),   .state_o(imix));

  // teste de uma coluna
  minisoc_aes_mix_columns     u_mix_col     (.state_i(col_in),  .state_o(col_mix));
  minisoc_aes_inv_mix_columns u_inv_mix_col (.state_i(col_mix), .state_o(col_inv));

  assign round_in = last ? shift : mix;

  // apendice B: start of round, after MixColumns e round keys
  logic [127:0] start_of_round [11] = '{
    128'h193de3bea0f4e22b9ac68d2ae9f84808,
    128'ha49c7ff2689f352b6b5bea43026a5049,
    128'haa8f5f0361dde3ef82d24ad26832469a,
    128'h486c4eee671d9d0d4de3b138d65f58e7,
    128'he0927fe8c86363c0d9b1355085b8be01,
    128'hf1006f55c1924cef7cc88b325db5d50c,
    128'h260e2e173d41b77de86472a9fdd28b25,
    128'h5a4142b11949dc1fa3e019657a8c040c,
    128'hea835cf00445332d655d98ad8596b0c5,
    128'heb40f21e592e38848ba113e71bc342d2,
    128'h3925841d02dc09fbdc118597196a0b32   // saida (texto cifrado)
  };
  logic [127:0] after_mixcolumns [9] = '{
    128'h046681e5e0cb199a48f8d37a2806264c,
    128'h584dcaf11b4b5aacdbe7caa81b6bb0e5,
    128'h75ec0993200b633353c0cf7cbb25d0dc,
    128'h0fd6daa9603138bf6fc0106b5eb31301,
    128'h25d1a9adbd11d168b63a338e4c4cc0b0,
    128'h4b868d6d2c4a8980339df4e837d218d8,
    128'h1415b5bf461615ec274656d7342ad843,
    128'h00512fd1b1c889ff54766dcdfa1b99ea,
    128'h473794ed40d4e4a5a3703aa64c9f42bc
  };
  logic [127:0] round_keys [10] = '{
    128'ha0fafe1788542cb123a339392a6c7605,
    128'hf2c295f27a96b9435935807a7359f67f,
    128'h3d80477d4716fe3e1e237e446d7a883b,
    128'hef44a541a8525b7fb671253bdb0bad00,
    128'hd4d1c6f87c839d87caf2b8bc11f915bc,
    128'h6d88a37a110b3efddbf98641ca0093fd,
    128'h4e54f70e5f5fc9f384a64fb24ea6dc4f,
    128'head27321b58dbad2312bf5607f8d292f,
    128'hac7766f319fadc2128d12941575c006e,
    128'hd014f9a8c9ee2589e13f0cc8b6630ca6
  };

  // apendice C.1 (key 000102..0f): istart, is_row, is_box e ik_sch
  logic [127:0] c1_istart [11] = '{
    128'h7ad5fda789ef4e272bca100b3d9ff59f,
    128'h54d990a16ba09ab596bbf40ea111702f,
    128'h3e1c22c0b6fcbf768da85067f6170495,
    128'hb458124c68b68a014b99f82e5f15554c,
    128'he8dab6901477d4653ff7f5e2e747dd4f,
    128'h36339d50f9b539269f2c092dc4406d23,
    128'h2d6d7ef03f33e334093602dd5bfb12c7,
    128'h3bd92268fc74fb735767cbe0c0590e2d,
    128'ha7be1a6997ad739bd8c9ca451f618b61,
    128'h6353e08c0960e104cd70b751bacad0e7,
    128'h00112233445566778899aabbccddeeff
  };
  logic [127:0] c1_is_row [10] = '{
    128'h7a9f102789d5f50b2beffd9f3dca4ea7,
    128'h5411f4b56bd9700e96a0902fa1bb9aa1,
    128'h3e175076b61c04678dfc2295f6a8bfc0,
    128'hb415f8016858552e4bb6124c5f998a4c,
    128'he847f56514dadde23f77b64fe7f7d490,
    128'h36400926f9336d2d9fb59d23c42c3950,
    128'h2dfb02343f6d12dd09337ec75b36e3f0,
    128'h3b59cb73fcd90ee05774222dc067fb68,
    128'ha761ca9b97be8b45d8ad1a611fc97369,
    128'h63cab7040953d051cd60e0e7ba70e18c
  };
  logic [127:0] c1_is_box [10] = '{
    128'hbd6e7c3df2b5779e0b61216e8b10b689,
    128'hfde3bad205e5d0d73547964ef1fe37f1,
    128'hd1876c0f79c4300ab45594add66ff41f,
    128'hc62fe109f75eedc3cc79395d84f9cf5d,
    128'hc81677bc9b7ac93b25027992b0261996,
    128'h247240236966b3fa6ed2753288425b6c,
    128'hfa636a2825b339c940668a3157244d17,
    128'h4915598f55e5d7a0daca94fa1f0a63f7,
    128'h89d810e8855ace682d1843d8cb128fe4,
    128'h00102030405060708090a0b0c0d0e0f0
  };
  logic [127:0] c1_ik_sch [10] = '{
    128'h549932d1f08557681093ed9cbe2c974e,
    128'h47438735a41c65b9e016baf4aebf7ad2,
    128'h14f9701ae35fe28c440adf4d4ea9c026,
    128'h5e390f7df7a69296a7553dc10aa31f6b,
    128'h3caaa3e8a99f9deb50f3af57adf622aa,
    128'h47f7f7bc95353e03f96c32bcfd058dfd,
    128'hb6ff744ed2c2c9bf6c590cbf0469bf41,
    128'hb692cf0b643dbdf1be9bc5006830b3fe,
    128'hd6aa74fdd2af72fadaa678f1d6ab76fe,
    128'h000102030405060708090a0b0c0d0e0f
  };

  task automatic check(string what, logic [127:0] got, logic [127:0] exp);
    if (got !== exp) begin
      $display("ERRO %s: %0h (esperado %0h)", what, got, exp);
      errors++;
    end
  endtask

  initial begin
    // db 13 53 45 -> 8e 4d a1 bc
    col_in = {4{32'hdb135345}};
    #1;
    check("MixColumns(db135345)", col_mix, {4{32'h8e4da1bc}});
    check("InvMixColumns(8e4da1bc)", col_inv, col_in);

    // apendice B, rodadas 1 a 10
    for (int r = 0; r < 10; r++) begin
      last      = (r == 9);
      state     = start_of_round[r];
      round_key = round_keys[r];
      #1;
      if (!last) begin
        check($sformatf("rodada %0d MixColumns", r + 1),    mix,     after_mixcolumns[r]);
        check($sformatf("rodada %0d InvMixColumns", r + 1), inv_mix, shift);
      end
      check($sformatf("rodada %0d AddRoundKey", r + 1), next, start_of_round[r + 1]);
    end

    // apendice C.1, rodadas 1 a 10 (a 10 nao tem InvMixColumns)
    for (int r = 0; r < 10; r++) begin
      istate = c1_istart[r];
      ikey   = c1_ik_sch[r];
      #1;
      check($sformatf("C.1 rodada %0d InvShiftRows", r + 1), ishift, c1_is_row[r]);
      check($sformatf("C.1 rodada %0d InvSubBytes", r + 1),  isub,   c1_is_box[r]);
      check($sformatf("C.1 rodada %0d saida", r + 1), (r == 9) ? iadd : imix, c1_istart[r + 1]);
    end

    if (errors == 0) $display("TEST PASSED");
    else             $fatal(1, "TEST FAILED: %0d erro(s)", errors);
    $finish;
  end

endmodule
