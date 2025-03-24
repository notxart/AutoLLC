# AutoLLC

## 警告

### 2025/03/15 將會是 AutoLLC 最後一個以個人名義發佈之版本，從下個版本開始，發佈位置將遷移至 [LimbusTraditionalMandarin](https://github.com/LimbusTraditionalMandarin/MAD)，正式成為繁體中文漢化組的官方發佈版本，並且會帶有圖形化介面，感謝大家過去對本個人項目的支持與喜愛

## 簡介 / Abstract

一款**單命令式安裝啟動器/腳本**，用於簡化**安裝邊獄巴士繁體中文語言包**時所需的複雜步驟！

## 使用方法

### 啟動器

1. 於 [**Releases**](https://github.com/notxart/AutoLLC/releases/latest) 下載 `AutoLLC.exe` 檔案。
2. 左鍵雙擊 `AutoLLC.exe` 運行啟動器即可。\
   ![Launcher](https://github.com/user-attachments/assets/e658d2d7-93fa-4842-ab9b-78f7effaaa62)
3. 對於**普通更新與啟動遊戲**請輸入 `1`；對於**重大變更**（需重新安裝）請輸入 `2`；**放棄安裝**請輸入 `3`。
4. 若出現類似 **NuGet provider is required to continue** 的資訊，請輸入 `y`，然後按下 `Enter` 鍵，繼續完成安裝。\
   ![Nuget](https://github.com/user-attachments/assets/2ab740b6-160e-4583-9299-13fcec5bf53f)

### ~~安裝腳本~~ (已棄用)

1. 開啟 `PowerShell`（**請不要使用 CMD 或 具有管理員權限的 PowerShell**）。如果您不知道怎麼做，請右鍵點擊 Windows 開始功能表，然後選擇 `PowerShell` 或 `終端機`（`Terminal`）。\
   ![PowerShell](https://github.com/user-attachments/assets/8127f94d-ce97-427f-8f39-8ccd18536e24)
2. 複製以下指令，並於 `PowerShell` 中貼上，然後按下 `Enter` 鍵，安裝腳本將自動運行。

   - 一般安裝更新

      ```PowerShell
      irm https://raw.githubusercontent.com/notxart/AutoLLC/refs/heads/main/src/hant.ps1 | iex
      ```

      ![Script](https://github.com/user-attachments/assets/89f55f7e-b320-493f-b6ef-194fe5cf33f5)

   - 重新安裝

      ```PowerShell
      iex "& { $(irm https://raw.githubusercontent.com/notxart/AutoLLC/refs/heads/main/src/hant.ps1) } -Reinstall"
      ```

      ![Script2](https://github.com/user-attachments/assets/4a3b2a55-8372-49af-8186-58e8222d27e4)

3. 若出現類似 **NuGet provider is required to continue** 的資訊，請輸入 `y`，然後按下 `Enter` 鍵，繼續完成安裝。\
   ![Nuget-script](https://github.com/user-attachments/assets/8ff32bf8-4e79-437b-8a90-0bd06f30c50e)
4. 在漢化補丁安裝完成後，會彈出以下 **BepInEx 小黑框**，請耐心等待其完成作業。\
   ![BepInEx](https://github.com/user-attachments/assets/896556ff-b53c-4e07-bac8-1e2064025df4)
5. 在遊戲介面彈出後，即可開始遊戲，**在遊玩過程中請注意不要關閉 BepInEx 小黑框**，祝您遊戲愉快！\
   ![Game](https://github.com/user-attachments/assets/211f39eb-9a89-4133-ae83-4533d7ef7147)

## 免責聲明

**重要提醒**：在使用本啟動器/腳本前，請仔細閱讀以下免責聲明。通過下載、安裝或運行該啟動器/腳本，即表示您已知悉並同意以下所有條款：

1. **本啟動器/腳本僅用於安裝「邊獄巴士」（Limbus Company）的繁體中文語言包插件**，不會干涉或參與遊戲的運行，亦不會破壞遊戲完整性，因此正常使用下，不應被認定為非法外掛程式，亦不構成封號理由。
2. **本啟動器/腳本屬於個人開發項目**，與遊戲開發商 Project Moon 無任何關聯。一切遊戲相關內容之最終解釋權僅由開發商 Project Moon 持有，與本啟動器/腳本作者無關。
3. **使用本啟動器/腳本的風險由使用者自行承擔**。本作者對於因使用本啟動器/腳本而可能產生的任何直接或間接損失不承擔任何責任，包括但不限於遊戲帳號被封禁、遊戲性能問題或其他技術故障。
4. **本啟動器/腳本所有功能均「按現狀」提供**，不保證其適用性、完整性、準確性或可靠性。使用者應自行確認其是否符合需求，並確保安裝過程嚴格遵守使用說明。
5. **使用者應自行備份相關數據及設置**，以防因使用本啟動器/腳本而引發的潛在問題。

如有任何疑問或建議，請聯繫開發者。感謝您的理解與配合。
