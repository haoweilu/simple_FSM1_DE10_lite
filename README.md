# 有限狀態機 (FSM) 實驗 - 實作於 DE10-Lite FPGA

本專案實作了一個有限狀態機 (FSM) 電路，並將其部署至 **Terasic DE10-Lite** 開發板上。透過板載的撥碼開關與按鍵控制狀態轉換，並由 LED 燈即時顯示目前狀態的輸出資料。

## ⚙️ 系統硬體腳位對照 (Pin Mapping)

為了在 DE10-Lite 上進行驗證，電路的 I/O 與開發板的實體元件連接關係如下：

| 電路訊號名稱 (FSM1) | 開發板實體元件 | 腳位編號 (Pin No.) | 說明 |
| :--- | :--- | :---: | :--- |
| `clk` | MAX10_CLK1_50 | `PIN_P11` | 板載 50MHz 系統時脈來源 |
| `rst_n` | **KEY[0]** | `PIN_B8` | 按鈕開關（按下為低電位 `0`，放開為高電位 `1`） |
| `in` | **SW[0]** | `PIN_C10` | 撥碼開關（往上撥為 `1`，往下撥為 `0`） |
| `out_data[0]` | **LEDR[0]** | `PIN_A8` | 狀態機輸出資料位元 0 (亮起代表 `1`) |
| `out_data[1]` | **LEDR[1]** | `PIN_A9` | 狀態機輸出資料位元 1 (亮起代表 `1`) |
| `out_data[2]` | **LEDR[2]** | `PIN_A10` | 狀態機輸出資料位元 2 (亮起代表 `1`) |
| `out_data[3]` | **LEDR[3]** | `PIN_B10` | 狀態機輸出資料位元 3 (亮起代表 `1`) |

> ⚠️ **注意：** `KEY[0]` 在 DE10-Lite 上預設有外部上拉電阻。因此，**放開按鈕時是高電位（運作狀態），按下按鈕時才是低電位（觸發重設）**。這完美符合程式碼中 `!rst_n` 的邏輯。

---

## 📊 狀態轉換與 LED 燈號對照

狀態機由輸入開關 `SW[0]` 控制轉換。在不同的狀態下，外面的 4 顆 LED 燈 (`LEDR[3:0]`) 會顯示對應的十六進位數值：

| 目前狀態 (State) | `SW[0]` 狀態 | 下一個狀態 | `LEDR[3:0]` 燈號表現 (十六進位) |
| :---: | :---: | :---: | :--- |
| **`s0`** | `0` → 保持 `s0`<br>`1` → 進入 `s1` | `s0` 或 `s1` | 🔴 🔴 🔴 🔴 (**`4'h0`** - 全滅) |
| **`s1`** | `1` → 保持 `s1`<br>`0` → 進入 `s2` | `s1` 或 `s2` | 🔴 🔴 🔴 🟢 (**`4'h1`** - 僅第 0 顆亮) |
| **`s2`** | `0` → 保持 `s2`<br>`1` → 進入 `s3` | `s2` 或 `s3` | 🟢 🔴 🔴 🔴 (**`4'h8`** - 僅第 3 顆亮) |
| **`s3`** | `1` → 保持 `s3`<br>`0` → 進入 `s0` | `s3` 或 `s0` | 🟢 🟢 🟢 🟢 (**`4'hf`** - 全亮) |

---

## 🛠️ Verilog 原始碼 (`FSM1.v`)

```verilog
module FSM1(
    input clk,
    input rst_n,
    input in,
    output reg [3:0] out_data
);
    // 狀態宣告
    parameter s0 = 0, s1 = 1, s2 = 2, s3 = 3;
    reg [2:0] state, next_state;

    // 1. 組合邏輯 - 狀態轉移判定
    always @(*) begin
        case(state)
            s0: next_state = in ? s1 : s0;
            s1: next_state = in ? s1 : s2;
            s2: next_state = in ? s3 : s2;
            s3: next_state = in ? s0 : s3;
            default: next_state = s0;
        endcase
    end
    
    // 2. 時序邏輯 - 狀態暫存器更新 (由 KEY[0] 非同步重設)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= s0;
        end else begin
            state <= next_state;
        end
    end

    // 3. 組合邏輯 - 輸出至 LEDR[3:0]
    always @(*) begin
        case(state)
            s0: out_data = 4'h0;
            s1: out_data = 4'h1;
            s2: out_data = 4'h8;
            s3: out_data = 4'hf;
            default: out_data = 4'h0;
        endcase		
    end

endmodule
