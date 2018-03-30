module BskPRM # (
	parameter [5:0]	VERSION 	= 6'h24,		// версия прошивки
	parameter [7:0]	PASSWORD	= 8'hA6,		// пароль
	parameter [3:0]	CS			= 4'b0111		// адрес микросхемы
) (
	inout  wire [15:0] bD,		// шина данных
	input  wire iRd,			// сигнал чтения (активный 0)
	input  wire iWr,			// сигнал записи (активный 0)
	input  wire iRes,			// сигнал сброса (активный 0)
	input  wire iBl,			// сигнал блокирования (активный 0)
	input  wire iKEnable,		// сигнал работы клменника (активный 0)
	input  wire [1:0] iA,		// шина адреса
	input  wire [3:0] iCS,		// сигнал выбора микросхемы	
	
	input  reg  [15:0] iComT,	// вход теста команд
	output wire [15:0] oCom,	// выход команд (активный 0)
	output wire [15:0] oComInd,	// выход индикации команд (активный 0)
	output wire oCS,			// выход адреса микросхемы (активный 0)
	output wire oEnable			// выход разрешения работы клеммника (активный 0)
);
	
	// код разрешения работы клеммника
	localparam ENABLE  = 8'hE1; 

	// команды 
	reg [15:0] com_hi;
	reg [15:0] com_low;

	// шина чтения
	reg [15:0] data_bus;

	// команды индикации
	reg [15:0] com_ind;

	// команда управления
	reg [7:0] control;

	// сигнал разрешения работы клеммника
	wire enable;

	// сигнал сброса (активный 1)
	wire aclr = !iRes;	

	// сигнал выбора микросхемы (активный 1)
	wire cs = (iCS == CS);

	initial begin
		com_hi = 16'h0000;
		com_low = 16'h0000;
		com_ind = 16'h0000;
		data_bus = 16'h0000;
		control = 8'h00;
	end 
	
	// сигнал выбора микросхемы (активный)
	assign oCS = !cs;

	// индикация команд
	assign oComInd = ~com_ind;
	
	// сигнал выбора чтения (0) /запись (1)
	assign rw = iRd && !iWr && cs;

	// двунаправленная шина данных
	assign bD = (iRd || !cs) ? 16'bZ : data_bus; 

	//
	assign enable = (control == ENABLE);

	// чтение данных 
	always @ (rw or iA)	begin : data_read
		if (!rw) begin
			case(iA)
				2'b00: begin
					data_bus <= iComT; 
				end
				2'b01: begin
					data_bus[07:0] <= com_low[15:12] + com_low[7:4];
					data_bus[15:8] <= com_hi[15:12] + com_hi[7:4];					
				end
				2'b10: begin
					data_bus <= 16'h0000;
				end
				2'b11: begin
					data_bus[07:0] <= (VERSION << 2) +(iKEnable << 1) + !enable;
					data_bus[15:8] <= PASSWORD;
				end
			endcase
		end
	end

	// запись внутренних регистров
	always @ (rw or iA or aclr) begin : data_write
		if (aclr) begin
			
		end
		else if (rw) begin
			case (iA)
				2'b00: ;
				2'b01: ;
				2'b10: com_ind = bD;
				2'b11: control = bD[7:0];
			endcase
		end
	end

endmodule