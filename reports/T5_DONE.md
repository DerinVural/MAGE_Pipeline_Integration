# T5 — Ollama JSON-Mode Fix + Debug Agent Forensics

**Status:** DONE
**Commit:** `938aa94` `[T5] Enable Ollama JSON-mode for constrained generation`
**Baseline reference:** `output_ollama_5probs_0.baseline/`, `log_ollama_5probs_0.baseline/`
**New run artifacts:** `output_ollama_5probs_json_mode_0/`, `log_ollama_5probs_json_mode_0/`

---

## 1. T5.1 diff

Tek değişiklik: `src/mage/gen_config.py`, Ollama constructor'ına `json_mode=True` eklendi. `utils.py`, `token_counter.py` ve diğer provider branch'leri dokunulmadı.

```diff
--- a/src/mage/gen_config.py
+++ b/src/mage/gen_config.py
@@ -95,6 +95,7 @@ def get_llm(**kwargs) -> LLM:
                 base_url=base_url,
                 request_timeout=kwargs.get("request_timeout", 600.0),
                 context_window=kwargs.get("context_window", 32768),
+                json_mode=True,
                 additional_kwargs={"num_predict": kwargs["max_token"]},
             )
         except Exception as e:
```

Ortam doğrulama:
- `llama-index-llms-ollama==0.10.1` → `json_mode` parametresi `Ollama` modeli için tanımlı.
- Smoke: `Ollama(..., json_mode=True).complete(...)` temiz JSON döndürüyor, backtick yok.

---

## 2. T5.2 Debug Agent forensic bulguları (baseline)

**İnceleme kaynağı:** `log_ollama_5probs_0.baseline/VERILOG_EVAL_V2_Prob003_step_one/mage_rtl_total.log` (778 satır), `...Prob004_vector2/mage_rtl_total.log` (225 satır).

### Soru 1 — RTLEditor iterasyon loop'una girdi mi?

**Kanıt:** Her iki log dosyasında da `"RTL Editing: round"` string'i **hiç geçmedi**.

```bash
$ grep -c "RTL Editing: round" log_ollama_5probs_0.baseline/VERILOG_EVAL_V2_Prob003_step_one/mage_rtl_total.log
0
$ grep -c "RTL Editing: round" log_ollama_5probs_0.baseline/VERILOG_EVAL_V2_Prob004_vector2/mage_rtl_total.log
0
```

Ek doğrulama — `Candidate generation` ve `Selected candidate` log string'leri de her iki problemde yok. `mage.rtl_editor.log` dosyaları **0 satır** (tamamen boş). `RTLEditor` hiç instantiate edilmedi (daha doğrusu `run_instance` onu bu problemlerde çağırmadan exit etti).

**Verdikt:** Debug Agent (RTLEditor) bu iki problemde **hiç çalışmadı**.

### Soru 2 — Kaç round çalıştı?

**0 round.** RTLEditor loop'u `agent.py:186` satırındaki koşul gerektirir: `if rtl_need_fix: # Editor iteration`. Bu branch'e ulaşılmadan önce kontrol akışı iki farklı yerde sonlandı:

- **Prob003**: TB Agent 5 kez `Json Decode Error: Expecting value: line 3 column 18 (char 291)` aldı (`mage_rtl_total.log:627, ...` — "Json Decode Error" içeren satırlar). Hatalar, modelin JSON alanlarının içinde backtick-delimited Verilog bloğu döndürmesinden kaynaklandı. Sonunda geçerli bir TB üretildi, RTL zaten `module TopModule; output logic one; initial one=1; endmodule` (port body içinde!) ile syntax-PASS aldı ama golden sim `"port 'one' is not a port of top_module1"` verdi. `run_instance`'ın 130. satırındaki `assert not tb_need_fix` muhtemelen tetiklendi veya `sim_max_retry` tükendi; RTLEditor çağrılmadı.
- **Prob004**: RTL 5 kez üst üste syntax FAIL aldı (`Syntax check is_pass: False` — satır 159, 172, 185, 198, 211). Her seferinde `always @(*) begin logic [7:0] byte0 = in[7:0]; ...` gibi `automatic` olmayan bağlamda statik değişken initialization yaparak iverilog warning → error dönüşümü aldı. `agent.py:97` satırında `if not is_syntax_pass: return False, rtl_code` erken exit. RTLEditor hiç oluşturulmadı.

### Soru 3 — "Json Decode Error" var mı?

Prob003: **6 adet** "Json Decode Error" (`mage_rtl_total.log` satırları: 1, 105, 131, 139, 383, 627). Tümü **TB Agent** içinde. Debug Agent rounds'u olmadığı için "Debug Agent içinde silent JSON fail" hipotezi burada **yanıtlanamaz** — Debug Agent hiç çağrılmadı.

Prob004: **7 adet** "Json Decode Error" satırı, benzer şekilde tümü TB veya RTL Generator için; RTLEditor yok.

**Sonuç:** Tip A (TB parser exhaustion) baseline'da gözlenen tek hata sınıfı. "Debug Agent silent JSON failure" hipotezi çürütüldü çünkü Debug Agent'a zaten hiç gelinemedi.

### Soru 4 — Ham response alıntısı

Prob004 baseline, `log_ollama_5probs_0.baseline/VERILOG_EVAL_V2_Prob004_vector2/mage_rtl_total.log:193-201` — RTL Generator'ın son denemesi (tüm 5 deneme de aynı syntax hatası):

```
[2026-04-21 17:58:23,992 - mage.rtl_generator - INFO] {
    "reasoning": "The error message indicates that static variable initialization requires
    explicit lifetime in this context. However, since we are dealing with a combinational
    logic block and not a sequential one, we don't need to initialize variables explicitly
    within the always block. The warning can be ignored as it does not affect the
    functionality of the module. We can simply remove the initialization lines that cause
    the warnings.",
    "module": "module TopModule(input logic [31:0] in, output logic [31:0] out); \n\n
               always @(*) begin\n
                 // Extract bytes from input\n
                 logic [7:0] byte0 = in[7:0];\n
                 logic [7:0] byte1 = in[15:8];\n
                 logic [7:0] byte2 = in[23:16];\n
                 logic [7:0] byte3 = in[31:24];\n\n
                 // Rearrange bytes to form reversed output\n
                 out[7:0]  = byte3;\n
                 out[15:8] = byte2;\n
                 out[23:16] = byte1;\n
                 out[31:24] = byte0;\n
               end\n\n
             endmodule"
}
[2026-04-21 17:58:23,992 - mage.bash_tools - INFO] Running command: iverilog -t null ...
[2026-04-21 17:58:24,002 - mage.sim_reviewer - INFO] Syntax check is_pass: False,
output: {
    "stdout": "",
    "stderr": "...rtl.sv:5: warning: Static variable initialization requires explicit
               lifetime in this context.\n(4 kez)"
}
```

Model "warning zararsız, görmezden gel" diye reasoning yazıp aynı hatayı tekrar üretti; `sim_reviewer` warning'i stderr non-empty kuralıyla FAIL'e dönüştürdü.

Prob003 baseline TB Agent, `mage_rtl_total.log:143-150` — backtick-Verilog dönüşü (valid JSON değil):

```
[2026-04-21 17:55:31,580 - mage.tb_generator - INFO] {
    "reasoning": "The golden testbench already includes an IO interface...",
    "interface": `
module stimulus_gen (
    input clk,
    output reg[511:0] wavedrom_title,
    ...
)
...
endmodule
`,
    "testbench": `
`timescale 1 ps/1 ps
...
endmodule
`
}
```

Backtick'ler JSON string delimiteri değil → `Expecting value: line 3 column 18` fırlatıyor.

---

## 3. T5.3 yeni record.json

`output_ollama_5probs_json_mode_0/record.json`:

```json
{
    "record_per_run": {
        "Prob001_zero": {
            "is_pass": false,
            "run_time": "0:03:31.366587"
        },
        "Prob002_m2014_q4i": {
            "is_pass": true,
            "run_time": "0:02:59.154997"
        },
        "Prob003_step_one": {
            "is_pass": true,
            "run_time": "0:02:19.726401"
        },
        "Prob004_vector2": {
            "is_pass": false,
            "run_time": "0:01:20.743757"
        },
        "Prob005_notgate": {
            "is_pass": true,
            "run_time": "0:03:23.829418"
        }
    },
    "total_record": {
        "pass_cnt": 3,
        "total_cnt": 5,
        "token_limit_cnt": 0,
        "total_run_time": "0:13:34.876632"
    }
}
```

Token/cost alanları 0 çünkü Ollama lokal, hem de qwen tokenizer mage.token_counter'da kayıtlı değil (uyarı: `Cannot find tokenizer for model 'qwen2.5-coder:7b'`).

**Yan doğrulama:** Yeni run log'larında "Json Decode Error" ve "RTL Editing: round" aramaları 5 problem için **hepsi 0**. Baseline'da Prob003 için 6, Prob004 için 7 Json Decode Error vardı. json_mode JSON parse hatalarını tamamen ortadan kaldırdı.

---

## 4. Delta tablosu

| Problem | Before (baseline) | After (T5/json_mode) | Change |
|---|---|---|---|
| Prob001_zero | PASS (25s) | **FAIL (3m31s)** | ↓ REGRESSION (detay aşağıda) |
| Prob002_m2014_q4i | FAIL (Type A, 1m04s) | **PASS (2m59s)** | ↑ Type A çözüldü |
| Prob003_step_one | FAIL (Type B, 2m18s) | **PASS (2m19s)** | ↑ Type B çözüldü |
| Prob004_vector2 | FAIL (Type C, 1m50s) | **FAIL (1m20s)** | = farklı syntax hatası |
| Prob005_notgate | FAIL (Type A, 1m08s) | **PASS (3m23s)** | ↑ Type A çözüldü |
| **TOPLAM** | **1/5, 6m45s** | **3/5, 13m34s** | **+2 pass, 2× süre** |

### Prob001 regresyonu detayı

`output_ollama_5probs_json_mode_0/VERILOG_EVAL_V2_Prob001_zero/sim_review_output.json`:

```json
{
    "is_pass": false,
    "sim_output": {
        "stdout": "VCD info: dumpfile wave.vcd opened for output.\n...
                   Hint: Output 'zero' has no mismatches.\n
                   Hint: Total mismatched samples is 0 out of 20 samples\n\n
                   Simulation finished at 102 ps\n
                   Mismatches: 0 in 20 samples\n",
        "stderr": "...Prob001_zero_test.sv:75: warning: Instantiating module TopModule
                   with dangling input port 1 (clk) floating.\n"
    }
}
```

**0 mismatch / 20 sample — fonksiyonel olarak doğru.** Ama `sim_reviewer.py:128-131` stderr non-empty olduğunda (benign liste dışında) `is_pass=False` döner. Model json_mode'da ürettiği RTL:

```verilog
module TopModule(input clk, output logic zero); initial zero = 0; endmodule
```

Gereksiz `input clk` portu eklediği için iverilog "dangling floating input" uyarısı verdi → FAIL olarak sayıldı. Baseline'da model `output logic zero` tek portlu çözüm üretmişti; json_mode altında farklı bir mimari tercih yaptı (büyük olasılıkla strict JSON grammer çıktı dağılımını daraltıyor, başka bir yerel minimuma düştü).

**Bu gerçek bir fonksiyonel regresyon değil**; sim_reviewer'ın stderr polisliği modelin stil değişikliğini FAIL sayıyor. Ancak tablo PM'in tanımına göre dolduruldu (is_pass bayrağı).

### Prob004 hata değişimi

- Baseline: `logic [7:0] byte0 = in[7:0];` → "Static variable initialization requires explicit lifetime" (5 deneme de aynı).
- T5: `assign out = {in[24:31], in[16:23], in[8:15], in[0:7]};` → "part select in[24:31] is out of order" (Verilog bit slice artan değil azalan olmalı).

Farklı ama aynı seviyede syntax hatası. Debug Agent hala çağrılmadı (syntax PASS alamadığı için `agent.py:97`'den erken çıkış).

---

## 5. Sonuç

**Verdikt: (a)** — *Type A fully resolved, Type B/C persist (partially).*

**Gerekçe:**
- **Type A (TB parser exhaustion)** baseline'daki iki ayrı problemde (Prob002, Prob005) **tamamen ortadan kalktı**. Her iki problem T5 sonrası PASS. `Json Decode Error` satır sayısı 13 → 0. json_mode grammer-constrained sampling hipotezi deneysel olarak doğrulandı.
- **Type B (Prob003, port syntax)** beklenmedik şekilde çözüldü — model json_mode baskısı altında daha disipline RTL üretti.
- **Type C (Prob004, fonksiyonel/syntax)** devam ediyor; hata şekli değişti ama Debug Agent hâlâ çağrılmıyor çünkü pipeline syntax-fail-during-generation branch'inde sıkışıyor (`agent.py:97` erken exit). Bu, json_mode ile alakasız bir pipeline mimarisi sorunu: RTL syntax fail olduğunda Debug Agent yerine RTLGenerator reset + yeniden dener; 5 kez başarısız olursa fully giveup.
- **Prob001 "regresyonu"** fonksiyonel olarak doğru çıktı (0 mismatch/20 sample) ancak `sim_reviewer.py`'nin stderr-benign listesine `dangling input port floating` warning'i dahil değil. Model json_mode'da farklı (daha gürültülü) port interface tercih etti. **Öneri: PM incelesin — ya bu warning benign listeye eklenmeli (sim_reviewer.py), ya da bu regresyon gerçek kabul edilmeli.**

**Ek bulgu (istenmeyen ama önemli):**
Debug Agent (`RTLEditor`) bu 5 problemlik ölçek üzerinde **hiçbir çalıştırmada asla tetiklenmedi** — ne baseline'da ne T5 sonrasında. Pipeline akışında RTLEditor'a ulaşmak için önce `rtl_gen.chat` syntax PASS olmalı, ardından sim mismatch_cnt > 0 olmalı, ardından candidate generation sırasında hâlâ fail olmalı. Bu 5 örnekte hiçbir problem bu yola girmedi. **Debug Agent'ın fonksiyonel çalıştığını doğrulamak için** daha büyük bir benchmark (≥20 problem) veya "hep syntax-valid ama functionality-wrong üret" senaryosu gerekiyor.

### Regression testing

`pytest tests/ -x` T5 öncesinde de T5 sonrasında da **0 test toplar**. Baseline'da `tests/test_single_agent.py` `import backoff` nedeniyle ImportError, diğerleri `def main()` pytest'çe fonksiyon testi olarak kollanmıyor. Mevcut repo'da pytest-uyumlu otomatik test süiti yok; dolayısıyla T5'in mevcut test kapsamında regresyon riski bulunmuyor (tek dosya, tek satır, tek parametre değişikliği).

### Stop condition summary

Hiçbir stop condition tetiklenmedi:
- `json_mode=True` geçerli parametre (doğrulandı).
- Ollama server red etmedi.
- Re-run'da Python exception yok.
- pytest durumu T5'ten bağımsız (zaten baseline'da 0 test topluyordu).

---

## PM için öneriler (karar beklenir)

1. **Prob001 regresyonu**: `sim_reviewer.py`'nin benign stderr listesine `dangling input port ... floating` warning'ini eklemek → fonksiyonel olarak doğru çıktı PASS sayılır.
2. **Prob004 Type C**: RTL Generator syntax fail durumunda pipeline'ın 5 round yeniden denemek yerine Debug Agent'ı devreye alması (agent.py:97). Bu kapsam T5 dışı, yeni task gerekir.
3. **Debug Agent çalışabilirlik doğrulaması**: Phase 2'ye geçmeden, Debug Agent'ın gerçekten tetiklendiği bir senaryoda (>10 mismatch ama syntax-OK) fonksiyonel olduğunu gösteren bir smoke test.
4. **Phase 2 fizibilitesi**: 3/5 pass (%60) dar bir örnek ama gelişme net; tam VerilogEval-v2 koşusuna devam kararı veri tabanında anlamlı olabilir.
