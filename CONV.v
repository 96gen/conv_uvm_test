`timescale 1ns/10ps

module CONV(
    input         clk,
    input         reset,
    output reg    busy,
    input         ready,
    output reg [11:0] iaddr,
    input  [19:0] idata,
    output reg    cwr,
    output reg [11:0] caddr_wr,
    output reg [19:0] cdata_wr,
    output reg    crd,
    output reg [11:0] caddr_rd,
    input  [19:0] cdata_rd,
    output reg [2:0]  csel
);

    // 狀態機定義
    localparam IDLE     = 3'd0,
               L0_FETCH = 3'd1,
               L0_WRITE = 3'd2,
               L1_FETCH = 3'd3,
               L1_WRITE = 3'd4,
               DONE     = 3'd5;

    reg [2:0] state, next_state;
    reg [11:0] pixel_cnt; // [11:6]:row [5:0]:col
    
    // Layer 0 專用暫存器
    reg [3:0] filter_cnt;
    reg [3:0] filter_cnt_d1; // 記錄前一拍的 Index 給權重 MUX 用
    reg signed [43:0] sum;
    reg pad_reg;
    
    // 【Setup Time 優化】新增乘法專用暫存器，用來打斷乘法與加法之間的 Critical Path
    reg signed [39:0] mult_reg; 
    
    // Layer 1 專用暫存器
    reg [2:0] pool_cnt;
    reg signed [19:0] max_val;

    // 組合邏輯選權重
    reg signed [19:0] w_val;
    always @(*) begin
        case(filter_cnt_d1)
            4'd0: w_val = 20'h0A89E;
            4'd1: w_val = 20'h092D5;
            4'd2: w_val = 20'h06D43;
            4'd3: w_val = 20'h01004;
            4'd4: w_val = 20'hF8F71;
            4'd5: w_val = 20'hF6E54;
            4'd6: w_val = 20'hFA6D7;
            4'd7: w_val = 20'hFC834;
            4'd8: w_val = 20'hFAC19;
            default: w_val = 20'h0;
        endcase
    end

    // 左上->右下, 為了對齊 tr, tc 擴充至 7bit
    reg signed [6:0] dr, dc;
    always @(*) begin
        case(filter_cnt)
            0: begin dr = -1; dc = -1; end
            1: begin dr = -1; dc =  0; end
            2: begin dr = -1; dc =  1; end
            3: begin dr =  0; dc = -1; end
            4: begin dr =  0; dc =  0; end
            5: begin dr =  0; dc =  1; end
            6: begin dr =  1; dc = -1; end
            7: begin dr =  1; dc =  0; end
            8: begin dr =  1; dc =  1; end
            default: begin dr = 0; dc = 0; end
        endcase
    end
    
    // 只要結果 < 0 或是 >= 64, [6] 絕對是 1
    wire [6:0] tr = {1'b0, pixel_cnt[11:6]} + dr;
    wire [6:0] tc = {1'b0, pixel_cnt[5:0]} + dc;
    wire is_pad = tr[6] | tc[6]; 
    wire [11:0] fetch_addr = {tr[5:0], tc[5:0]};

    // 【語法優化】使用 MUX 替代 AND 邏輯來處理負數補 0，對 Synthesis 更友善
    wire signed [19:0] mul_in = pad_reg ? 20'sd0 : idata;

    // 直接利用 sum[43] 判斷負數完成 ReLU
    wire [19:0] relu_out = sum[43] ? 20'd0 : sum[35:16];

    // Max Pooling 記憶體位址預先計算
    wire [11:0] p_addr_0 = {pixel_cnt[9:5], 1'b0, pixel_cnt[4:0], 1'b0};
    wire [11:0] p_addr_1 = {pixel_cnt[9:5], 1'b0, pixel_cnt[4:0], 1'b1};
    wire [11:0] p_addr_2 = {pixel_cnt[9:5], 1'b1, pixel_cnt[4:0], 1'b0};
    wire [11:0] p_addr_3 = {pixel_cnt[9:5], 1'b1, pixel_cnt[4:0], 1'b1};

    // ==========================================
    // 第一段：狀態暫存器 (State Register)
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else       state <= next_state;
    end

    // ==========================================
    // 第二段：次態組合邏輯 (Next State Logic)
    // ==========================================
    always @(*) begin
        next_state = state; 
        case (state)
            IDLE: begin
                if (ready) next_state = L0_FETCH;
            end
            
            L0_FETCH: begin
                // 【時序變更】因為加入 Pipeline，累積需要多耗 1 拍，故從 9 改為 10
                if (filter_cnt == 10) next_state = L0_WRITE;
            end
            
            L0_WRITE: begin
                if (pixel_cnt == 12'd4095) next_state = L1_FETCH;
                else next_state = L0_FETCH;
            end
            
            L1_FETCH: begin
                if (pool_cnt == 4) next_state = L1_WRITE;
            end
            
            L1_WRITE: begin
                if (pixel_cnt == 12'd1023) next_state = DONE;
                else next_state = L1_FETCH;
            end
            
            DONE: begin
                next_state = DONE; 
            end
            
            default: next_state = IDLE;
        endcase
    end

    // ==========================================
    // 第三段：資料路徑與輸出 (Datapath & Output Logic)
    // ==========================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            busy <= 0;
            cwr <= 0;
            crd <= 0;
            iaddr <= 0;
            caddr_wr <= 0;
            caddr_rd <= 0;
            cdata_wr <= 0;
            csel <= 0;
            pixel_cnt <= 0;
            filter_cnt <= 0;
            filter_cnt_d1 <= 0;
            sum <= 0;
            mult_reg <= 0; // 重置乘法暫存器
            pool_cnt <= 0;
            max_val <= 0;
            pad_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (ready) begin
                        busy <= 1;
                        pixel_cnt <= 0;
                        filter_cnt <= 0;
                        sum <= 44'h000013108000; // 預載 Bias + Rounding
                    end
                end
                
                L0_FETCH: begin
                    cwr <= 0;

                    // 1. 發送位址階段 (Cycle 0~8)
                    if (filter_cnt < 9) begin
                        iaddr <= is_pad ? 12'd0 : fetch_addr;
                        pad_reg <= is_pad;
                        filter_cnt_d1 <= filter_cnt; 
                    end

                    // 2. 乘法階段 (Cycle 1~9)：將結果鎖進 mult_reg 打斷 Critical Path
                    if (filter_cnt > 0 && filter_cnt <= 9) begin
                        mult_reg <= mul_in * w_val;
                    end

                    // 3. 累加階段 (Cycle 2~10)：加上一拍存入的乘積
                    if (filter_cnt > 1) begin
                        sum <= sum + mult_reg;
                    end

                    // 計數器控制
                    if (filter_cnt != 10) begin
                        filter_cnt <= filter_cnt + 1;
                    end
                end
                
                L0_WRITE: begin
                    cwr <= 1;
                    csel <= 3'b001;
                    caddr_wr <= pixel_cnt;
                    cdata_wr <= relu_out;

                    if (pixel_cnt == 12'd4095) begin
                        pixel_cnt <= 0;
                        pool_cnt <= 0;
                    end else begin
                        pixel_cnt <= pixel_cnt + 1;
                        filter_cnt <= 0;
                        sum <= 44'h000013108000; // 重置為 Bias + Rounding
                    end
                end
                
                L1_FETCH: begin
                    cwr <= 0;

                    case (pool_cnt)
                        0: begin 
                            caddr_rd <= p_addr_0;      
                            crd <= 1; 
                            csel <= 3'b001; 
                            pool_cnt <= 1;
                        end
                        1: begin 
                            caddr_rd <= p_addr_1;  
                            max_val <= cdata_rd; 
                            pool_cnt <= 2;
                        end
                        2: begin 
                            caddr_rd <= p_addr_2; 
                            max_val <= ($signed(cdata_rd) > $signed(max_val)) ? cdata_rd : max_val; 
                            pool_cnt <= 3;
                        end
                        3: begin 
                            caddr_rd <= p_addr_3; 
                            max_val <= ($signed(cdata_rd) > $signed(max_val)) ? cdata_rd : max_val; 
                            pool_cnt <= 4;
                        end
                        4: begin 
                            crd <= 0; 
                            max_val <= ($signed(cdata_rd) > $signed(max_val)) ? cdata_rd : max_val; 
                        end
                    endcase
                end
                
                L1_WRITE: begin
                    cwr <= 1;
                    csel <= 3'b011;
                    caddr_wr <= pixel_cnt;
                    cdata_wr <= max_val;

                    if (pixel_cnt != 12'd1023) begin
                        pixel_cnt <= pixel_cnt + 1;
                        pool_cnt <= 0;
                    end
                end
                
                DONE: begin
                    busy <= 0;
                    cwr <= 0;
                    crd <= 0;
                end
            endcase
        end
    end
endmodule