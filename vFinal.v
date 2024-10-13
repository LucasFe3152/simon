module dec7seg(
    input [1:0] A,    // Entrada A
    output reg [6:0] Y    // Saída
);
    always @(*) begin
        case (A)
            2'b00: Y <= 7'b1111110; // 0
            2'b01: Y <= 7'b0110000; // 1
            2'b10: Y <= 7'b1101101; // 2
            2'b11: Y <= 7'b0000000; // 3
            default: Y <= 7'b0000000; // Apagar o display
        endcase
    end
endmodule

module exibeSeq(
    output reg [6:0] display,
    input wire [15:0][1:0] seq,
    input clk,
    input wire [3:0] externalCounter
);
    reg [3:0] internalCounter;

    always @(posedge clk) begin
        if (internalCounter < externalCounter) begin
            internalCounter <= internalCounter + 1'b1;
        end
        else begin
            internalCounter <= 4'hF; // Reinicia o contador
        end
    end

    dec7seg dec1(.Y(display), .A(seq[internalCounter]));
endmodule

/////////////////////////////////////////////

module button_press_detector (
    input wire rst,        // Reset assíncrono
    input wire button1,    // Sinal do botão 1
    input wire button2,    // Sinal do botão 2
    input wire button3,    // Sinal do botão 3
    output reg [1:0] button_id,  // Identifica o botão pressionado (00: botão 1, 01: botão 2, 10: botão 3, 11: nenhum)
    output reg button_pressed   // Indica que algum botão foi pressionado
);

    reg button1_prev, button2_prev, button3_prev; // Estados anteriores dos botões

    always @(*) begin
        if (rst) begin
            button1_prev <= 1'b1; 
            button2_prev <= 1'b1;
            button3_prev <= 1'b1;
            button_id <= 2'b00; 
            button_pressed <= 1'b0; 
        end else begin
            button1_prev <= button1;
            button2_prev <= button2;
            button3_prev <= button3;
            
            if (button1_prev == 1'b1 && button1 == 1'b0) begin
                button_id <= 2'b00;    
                button_pressed <= 1'b1;
            end else if (button2_prev == 1'b1 && button2 == 1'b0) begin
                button_id <= 2'b01;     
                button_pressed <= 1'b1;
            end else if (button3_prev == 1'b1 && button3 == 1'b0) begin
                button_id <= 2'b10;     
                button_pressed <= 1'b1;
            end else begin
                button_id <= 2'b11;     
                button_pressed <= 1'b0; 
            end
        end
    end
endmodule

/////////////////////////////////////////////

module compare_button(
    input [1:0] button_id,
    input [15:0] [1:0] seq,
    input [3:0] count,
    input button_pressed,
    input rst,
    output reg match
);

    reg [1:0] current_value;

    always@(*) begin
        current_value <= seq[count];

        if(button_id == current_value && button_pressed == 1) begin
            match = 1'b1;
        end
        else begin
            match = 1'b0;
        end
    end
endmodule

/////////////////////////////////////////////

module counter_4bits (
    input clk,            
    input increment,         
    input reset,              
    output reg [3:0] count    
);
    
    always @(posedge clk) begin
        if (reset) begin
            count <= 4'b0000;  
        end 
        else if (increment) begin
            if (count < 4'b1110) begin 
                count <= count + 4'b0001; 
            end
        end
    end
endmodule

/////////////////////////////////////////////

module check_sequentially_is_over (
    input [3:0] count,      
    output reg game_end     
);
    always @(*) begin
        if (count == 4'hE) 
            game_end = 1'b1; 
        else
            game_end = 1'b0; 
    end

endmodule


module check_button_sequentially(
    input [3:0] count,
    input [3:0] current_value,
    output reg seq_end
);

    always @(*) begin
        if (count == current_value) 
            seq_end = 1'b1; 
        else
            seq_end = 1'b0; 
    end

endmodule

/////////////////////////////////////////////

module game_win(
    input [3:0] seqAtual,
    output reg game_win
);
    always@(*) begin
        if(seqAtual == 4'b1110)begin
            game_win = 1'b1;
        end
        else begin
            game_win = 1'b0;
        end
    end
endmodule


/////////////////////////////////////////////

module game_over_module(
    input[3:0] seqAtual,
    input[3:0] seqCorreta,
    output reg game_over

);

    always@(*) begin
        if(seqAtual != seqCorreta)begin
            game_over = 1'b1;
        end
        else begin
            game_over = 1'b0;
        end
    end
endmodule


//////////////////////////////////////////

module finite_state_machine(
    input clk, 
    input rst, 
    input [2:0] botoes,
    output [6:0] display
);

    // Registrador de estados
    reg [2:0] state;
    reg match;
    reg [2:0] next_state;
    reg seq_end;
    reg game_end;
    reg [3:0] external_counter;
    reg [3:0] btn_counter;

    wire btn_pressed;
    wire [1:0] button_id;
    wire [15:0][1:0] seq;  // Sequência de LEDs (este sinal deve ser definido ou gerado em algum lugar)
    wire button_pressed;

    assign seq[0] = 2'b00;
    assign seq[1] = 2'b01;
    assign seq[2] = 2'b10;
    assign seq[3] = 2'b01;
    assign seq[4] = 2'b00;
    assign seq[5] = 2'b01;
    assign seq[6] = 2'b10;
    assign seq[7] = 2'b01;
    assign seq[8] = 2'b00;
    assign seq[9] = 2'b01;
    assign seq[10] = 2'b10;
    assign seq[11] = 2'b01;
    assign seq[12] = 2'b00;
    assign seq[13] = 2'b01;
    assign seq[14] = 2'b10;
    assign seq[15] = 2'b11;

    // Codificação dos estados
    parameter gerarSeqLeds = 3'b000,
              exibeSeqLeds = 3'b001,
              esperarBtn = 3'b010,
              compararBtn = 3'b011,
              verificarSeqFim = 3'b100,
              gameWin = 3'b101,
              gameOver = 3'b110,
              intermediario8 = 3'b111;

    // Estado inicial
    always @(posedge clk) begin
        if (rst)begin
            state <= exibeSeqLeds;
            external_counter <= 4'h0;
            btn_counter <= 4'h0;
        end
        else begin
            state <= next_state;
        end
    end 

    always @(*) begin
        case (state)
            exibeSeqLeds: begin
                next_state <= esperarBtn;
            end

            esperarBtn: begin
                next_state <= compararBtn;
            end

            compararBtn: begin
                if (~match) 
                    next_state <= gameOver;
                else 
                    next_state <= verificarSeqFim;
            end

            verificarSeqFim: begin
                if (game_end) 
                    next_state <= gameWin;
                else if (seq_end) 
                    next_state <= exibeSeqLeds;
                else 
                    next_state <= esperarBtn;
            end

            gameWin: begin
                next_state <= intermediario8;
            end

            gameOver: begin
                next_state <= intermediario8;
            end

            intermediario8: begin
                if (rst) 
                    next_state <= exibeSeqLeds;
            end
        endcase
    end

    // Instanciação dos módulos fora do bloco always
    exibeSeq exibe(
        .display(display), 
        .seq(seq), 
        .clk(clk), 
        .externalCounter(external_counter)
    );

    button_press_detector detector(
        .rst(rst), 
        .button1(botoes[0]), 
        .button2(botoes[1]), 
        .button3(botoes[2]), 
        .button_id(button_id), 
        .button_pressed(button_pressed)
    );

    compare_button compara_btn(
        .button_id(button_id), 
        .seq(seq), 
        .count(btn_counter), 
        .button_pressed(button_pressed), 
        .rst(rst), 
        .match(match)
    );

    check_sequentially_is_over seq_acabou(
        .count(external_counter), 
        .game_end(game_end)
    );

    check_button_sequentially btn_acabou(
        .count(btn_counter), 
        .current_value(external_counter), 
        .seq_end(seq_end)
    );

endmodule


module main(
    input clk, 
    input rst,
    input [2:0] botoes,  
    output [6:0] display
);


finite_state_machine fsm(.clk(clk), .rst(rst), 
                         .display(display), .botoes(botoes));

endmodule