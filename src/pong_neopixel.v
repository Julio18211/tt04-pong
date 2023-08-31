module tt_um_pong_neopixel(
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
	
	wire start;
	wire driver;

	wire p1_up;
	wire p1_down;
	wire p2_up;
	wire p2_down;

	wire clk_5;
	reg clk_5_last;
	reg clk_5_new;
	
	wire signal_1,signal_0;
	wire slow;
	
	wire p1_up_debounced;
	reg last_p1_up;
	reg now_p1_up;
	
	wire p1_down_debounced;
	reg last_p1_down;
	reg now_p1_down;

	wire p2_up_debounced;
	reg last_p2_up;
	reg now_p2_up;
	
	wire p2_down_debounced;
	reg last_p2_down;
	reg now_p2_down;
	//start
	wire start_debounced;
	reg last_start;
	reg now_start;
	
	//pelota
	wire pelota_clk;
	reg pel_last;
	reg pel_now;
	reg [5:0] pos_pel;
	reg [5:0] vel_x;
	reg [5:0] vel_y;
	
	
	reg signal_sel; //determinar si se enviaran [255,255,255] o [0,0,0]
	reg res_signal; // determinar si se enviará una señal de reset
	reg [4:0]counter_bits; //cantidad de bits enviados
	reg [6:0] counter_leds;//numero de led a encender

	reg [3:0] leds; //datos de led (1 encendido, 0 apagado)

	assign start   = ui_in[0];
	assign p1_up   = ui_in[1];
	assign p1_down = ui_in[2];
	assign p2_up   = ui_in[3];
	assign p2_down = ui_in[4];
	
	assign uio_out[0:7] = 8'b00000000;
	assign uio_oe[0:7]  = 8'b00000000;
	assign uo_out[1:7]  = 7'b0000000;

	wave_shape U2(clk_5,rst_n,signal_1,signal_0);//generar la señal a enviar
	slow_clk   U3(clk_5,slow,pelota_clk);
	
	debounce U4(p1_up,slow,p1_up_debounced);
	debounce U5(p1_down,slow,p1_down_debounced);

	debounce U6(p2_up,slow,p2_up_debounced);
	debounce U7(p2_down,slow,p2_down_debounced);
	
	debounce U8(start,slow,start_debounced);
	
	// señales para encender (signal_1) o apagar (signal_0)
	assign driver_out = (signal_sel)? signal_1 : signal_0;  
	assign driver     = (res_signal)? 1'b0 : driver_out;
	assign uo_out[0]  = driver;

    //posición de la paleta izquieda, ultimo led encendido (ancho 4)
    reg [2:0] pos_izq;

    //posición de la paleta derecha, ultimo led encendido (ancho 4)
    reg [2:0] pos_der;
		
	always@(posedge clk) begin
		
	
		// condiciones iniciales
		if(~rst_n) begin
			counter_bits = 5'd0;
			counter_leds = 3'd0;
			signal_sel = 1'b0;
			res_signal = 1'b0;
			leds = 4'b1001;   
         pos_der=3'd0;
			pos_izq=3'd0;
			pos_pel=6'd20;
			vel_x = 6'd63;
			vel_y = 6'd8;
		end

		last_p1_up = now_p1_up;
		now_p1_up = p1_up_debounced;
		
		if(last_p1_up==1'b1 && now_p1_up == 1'b0 && pos_izq < 3'd4) pos_izq = pos_izq + 3'd1;
		
		last_p1_down = now_p1_down;
		now_p1_down = p1_down_debounced;
		
		if(last_p1_down==1'b1 && now_p1_down == 1'b0 && pos_izq > 3'd0) pos_izq = pos_izq - 3'd1;

		last_p2_up = now_p2_up;
		now_p2_up = p2_up_debounced;
		
		if(last_p2_up==1'b1 && now_p2_up == 1'b0 && pos_der < 3'd4) pos_der = pos_der + 3'd1;
		
		last_p2_down = now_p2_down;
		now_p2_down = p2_down_debounced;
		
		if(last_p2_down==1'b1 && now_p2_down == 1'b0 && pos_der > 3'd0) pos_der = pos_der - 3'd1;
		
		last_start = now_start;
		now_start = start_debounced;
		
		if(last_start==1'b1 && now_start == 1'b0) begin
			vel_x = 6'd63;
			vel_y = 6'd8;
		end
		// --------- movimiento de la pelota -----------------------------------
		pel_last = pel_now;
		pel_now = pelota_clk;
		
		//colision con paleta izquieda
		if(		pos_pel == (pos_izq*8+1) 
            || pos_pel == ((pos_izq+1)*8+1) 
            || pos_pel == ((pos_izq+2)*8 +1)
            || pos_pel == ((pos_izq+3)*8+1) ) vel_x = 6'd1;
		//colision con paleta derecha
		if(		pos_pel == ((pos_der+1)*8-2)
            || pos_pel == ((pos_der+2)*8-2)
            || pos_pel == ((pos_der+3)*8-2)
            || pos_pel == ((pos_der+4)*8-2) ) vel_x = 6'd63;
		
		//colision parte inferior
		if(pos_pel > 6'd57 && pos_pel < 6'd63 ) vel_y = 6'd56;
		//colision parte superior
		if(pos_pel > 6'd0 && pos_pel < 6'd7 ) vel_y = 6'd8 ;
		//fin del juego
		if(   pos_pel == 0
			|| pos_pel == 8
			|| pos_pel == 16
			|| pos_pel == 24
			|| pos_pel == 32
			|| pos_pel == 40
			|| pos_pel == 48
			|| pos_pel == 56
			|| pos_pel == 7
			|| pos_pel == 15
			|| pos_pel == 23
			|| pos_pel == 31
			|| pos_pel == 39
			|| pos_pel == 47
			|| pos_pel == 55
			|| pos_pel == 63) begin
			
				pos_pel=6'd20;
				vel_x = 6'd0;
				vel_y = 6'd0;
			
			end
			
		if(pel_now==1'b1 && pel_last == 1'b0) pos_pel =pos_pel+ vel_x + vel_y;
		
		
    // incrementar el conteo de bits enviados
		clk_5_last = clk_5_new;
		clk_5_new = driver_out;
		
		if(clk_5_last == 1'b0 && clk_5_new == 1'b1)  counter_bits = counter_bits + 5'd1;
    // si se enviaron 24 bits, el valor de un led esta establecido
		if(counter_bits==5'd24) begin

            counter_leds = counter_leds + 3'd1;
            counter_bits = 5'd0;
            
		end
    // ---- ENVIAR DATOS PARA ENCENDER O APAGAR LED ------------------------
        if(counter_leds == (pos_izq*8+1) 
            || counter_leds == ((pos_izq+1)*8+1) 
            || counter_leds == ((pos_izq+2)*8 +1)
            || counter_leds == ((pos_izq+3)*8+1)
            || counter_leds == ((pos_der+1)*8)
            || counter_leds == ((pos_der+2)*8)
            || counter_leds == ((pos_der+3)*8)
            || counter_leds == ((pos_der+4)*8)
				|| counter_leds == (pos_pel+1)) signal_sel = 1'd1;
        else signal_sel = 1'd0;
    
        if(7'd0 < counter_leds && counter_leds < 7'd65) res_signal = 1'b0;
        else res_signal = 1'b1;
    end
	

endmodule
