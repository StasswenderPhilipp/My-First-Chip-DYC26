package user_pkg;

  //////////////////
  // User Manager //
  //////////////////
  
  // None


  ///////////////////////
  // User Subordinates //
  ///////////////////////

  /// Enum with user domain demultiplexer subordinate idxs
  typedef enum int {
    UserError  = 0,
    UserDesign = 1
  } user_demux_outputs_e;

  /// Address rules given to user domain demultiplexer
  localparam croc_pkg::addr_map_rule_t [0:0] user_addr_map = '{
    // Dein Chip bekommt 4KB Adressraum (0x1000 = 4096 Bytes)
    // Das reicht locker für deine ~15 Register (je 4 Bytes = 60 Bytes)
    '{ 
      idx: UserDesign,  
      start_addr: croc_pkg::UserBaseAddr, 
      end_addr: (croc_pkg::UserBaseAddr + 32'h0000_1000) // 4KB statt 256MB
    }
  };
  
  // +1 for additional OBI error
  localparam int unsigned NumDemuxSbr = $size(user_addr_map) + 1; 

endpackage