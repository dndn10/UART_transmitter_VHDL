library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_unsigned.all ;
entity tb_transmitter is
  -- Test bench of UART transmitter
end tb_transmitter ;
architecture arc_tb_transmitter of tb_transmitter is
   component transmitter
      port ( resetN     : in  std_logic                    ; -- a-sync reset
             clk        : in  std_logic                    ; -- clock
             write_din  : in  std_logic                    ; -- send enable
             din        : in  std_logic_vector(7 downto 0) ; -- parallel in
             tx         : out std_logic                    ; -- serial out
             tx_ready   : out std_logic                    ) ;
   end component ;
   signal resetN     : std_logic ; -- actual resetN (active low)
   signal clk        : std_logic ; -- actual clock
   signal write_din  : std_logic ; -- actual send enable
   signal din        : std_logic_vector(7 downto 0) ; -- actual parallel in
   signal txrx       : std_logic ; -- from hardware transmitter to receiver
   constant bit_time : time := 8680 ns ;             -- 115200 BPS (baud)
   signal dout       : std_logic_vector(7 downto 0) ; -- int Parallel output
begin 
   -- Transmitter instantiation (named association)
   eut: transmitter
      port map ( resetN    => resetN      ,
                 clk       => clk         ,
                 write_din => write_din   ,
                 din       => din         ,
                 tx        => txrx        ,
                 tx_ready  => open        ) ;
   -- Clock process (50 MHz)
   process
   begin
      clk <= '0' ;  wait for 20 ns ;
      clk <= '1' ;  wait for 20 ns ;
   end process ;   
   -- Active low reset pulse
   resetN <= '0' , '1' after 40 ns ;

   -- Transmission activation & test vectors process
   process
      variable data_send : std_logic_vector(7 downto 0) ;
   begin
      -- wait for end of async reset
      din <= "XXXXXXXX" ; write_din <= '0' ;  
      wait for 40 ns ;
      -----------------------------------------  vector 1    
      report "sending the H character (01001000b=48h=72d)" ; 
      data_send := "00000000" + character'pos('H') ; 
      din <= data_send ; write_din <= '1' ;  
      wait for 40 ns ;
      din <= "XXXXXXXX" ;  write_din <= '0' ;  
      wait for 11 * bit_time ;
      assert dout = data_send report "bad transmission #1" severity error ;
      -----------------------------------------  vector 2     
      report "sending the i character (01101001b=69h=105d)" ; 
      data_send := "00000000" + character'pos('i') ;  
      din <= data_send ; write_din <= '1' ;  
      wait for 40 ns ;
      din <= "XXXXXXXX" ;  write_din <= '0' ;  
      wait for 11 * bit_time ;
      assert dout = data_send report "bad transmission #2" severity error ;      
      -----------------------------------------  vector 3      
      report "sending the CR character (00001101=0Dh=13d)" ; 
      data_send := "00000000" + character'pos(CR) ;  
      din <= data_send ; write_din <= '1' ;  
      wait for 40 ns ;
      din <= "XXXXXXXX" ;  write_din <= '0' ;  
      wait for 11 * bit_time ;
      assert dout = data_send report "bad transmission #3" severity error ;          
      -----------------------------------------  vector 4      
      report "sending the LF character (00001010=0Ah=10d)" ; 
      data_send := "00000000" + character'pos(LF) ;  
      din <= data_send ; write_din <= '1' ;  
      wait for 40 ns ;
      din <= "XXXXXXXX" ;  write_din <= '0' ;  
      wait for 11 * bit_time ;
      assert dout = data_send report "bad transmission #4" severity error ;
      -----------------------------------------      
      report "end of test vectors" ;
      wait ;
   end process ;
 
   -- tx waveform tester (receiver)
   process
      variable dint : std_logic_vector(7 downto 0) ;
   begin
      dint := ( others => '0' ) ;
      wait until falling_edge(txrx) ;
      wait for bit_time / 2 ;
      if txrx = '0' then
         for i in 0 to 7 loop
            wait for bit_time ;
            dint(i) := txrx ;
         end loop ;
         wait for bit_time ;
         assert txrx = '1' report "Bad stop bit" severity error ;
         dout <= dint ;
      else
         report "A too short start bit" ;
      end if ;
   end process ;
end arc_tb_transmitter ;
        