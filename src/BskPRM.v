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
	
	input  wire [15:0] iComT,	// вход теста команд
	output wire [15:0] oCom,	// выход команд (активный 0)
	output wire [15:0] oComInd,	// выход индикации команд (активный 0)
	output wire oCS,			// выход адреса микросхемы (активный 0)
	output wire oEnable,		// выход разрешения работы клеммника (активный 0)

	output wire [15:0] debug	// выход отладки
);
	
	// код разрешения работы клеммника
	localparam ENABLE  = 8'hE1; 

	// команды
	reg [15:0] com;

	// флаг ошибки в командах
	reg [3:0] com_err;

	// команды индикации
	reg [15:0] com_ind;

	// команда управления
	reg [7:0] control;	

	// набор сигналов для чтения
	wire [15:0] in3;

	// шина чтения
	wire [15:0] data_bus;

	initial begin
		control = 8'h00;
		com  = 16'h0000;
		com_err = 4'b1111;
		com_ind = 16'h0000;	
	end
	
	// сигнал сброса (активный 1)
	assign aclr = !iRes;	

	// сигнал выбора микросхемы (активный 1)
	assign cs = (iCS == CS);

	// сигнал блокировки (активный 1)
	assign bl = !(iBl && iRes);

	// сигнал разрешения работы клеммника (активный 1)
	assign enable  = (control == ENABLE);

	// выход разрешения работы клеммника
	assign oEnable = !enable || bl; 

	// сигнал выбора микросхемы (активный)
	assign oCS = !cs;

	// индикация команд
	assign oComInd = ~com_ind;
	
	// выход команд
	assign oCom = (com_err || bl) ? 16'hFFFF : com;
	
	// набор сигналов для считывания 
	assign in3 = (PASSWORD << 8) + (VERSION << 2) + (iKEnable << 1) + enable;
	
	// шина чтения
	assign data_bus =	(iA == 2'b00) ? iComT : 
						(iA == 2'b01) ? com : 
						(iA == 2'b10) ? 16'h0000 : in3;

	// двунаправленная шина данных
	assign bD = (iRd || !cs) ? 16'bZ : data_bus; 

	// тестовые сигналы
	assign debug = 16'h0000;

	// запись внутренних регистров
	always @ (cs or iWr or iA or aclr) begin : data_write
		if (aclr) begin
			control <=  8'h00;
			com <= 16'h0000;
			com_err <= 4'b1111;
			com_ind <= 16'h0000;	
		end
		else if (cs && !iWr) begin
			case (iA)
				2'b00: begin 
					com[3:0] <= bD[7:4];
					com[7:4] <= bD[15:12];	
					com_err[0] <= !(bD[3:0] == ~bD[7:4]);
					com_err[1] <= !(bD[11:8] == ~bD[15:12]);
				end
				2'b01: begin
					com[11:8] <= bD[7:4];
					com[15:12] <= bD[15:12];
					com_err[2] <= !(bD[3:0] == ~bD[7:4]);
					com_err[3] <= !(bD[11:8] == ~bD[15:12]);
				end
				2'b10: begin
					com_ind <= bD;
				end
				2'b11: begin 
					control <= bD[7:0];
				end
			endcase
		end
	end

endmodule