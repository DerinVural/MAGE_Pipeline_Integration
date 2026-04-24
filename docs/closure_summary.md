# MAGE Pipeline Integration — Project Closure Document

_Versiyon 2 — 22 Nisan 2026 — Final_

Bu doküman projenin kapanış raporudur. İki amacı var:
1. **Executive summary** — projenin ne yaptığı, ne bulduğu, neden önemli
2. **Tez/rapor iskeleti** — bu projeyi akademik yazıma dökerken kullanabileceğin yapı

---

## 1. Executive Summary

### 1.1. Projenin amacı (orijinal — Plan v1)

[MAGE paper](https://arxiv.org/abs/2412.07822) (Zhao et al., 2024 — UCSD/DAC),
Claude 3.5 Sonnet ile VerilogEval-Human v2 benchmark'ında %95.7 pass@1
elde eden, 4 uzmanlaşmış LLM agent'tan oluşan bir RTL kod üretim sistemi
sundu. Sistemin iki anahtar katkısı:

- **High-Temperature RTL Sampling** — n=20 candidate'tan en iyisini seçme
- **Verilog-State Checkpoint Debug Mechanism** — fonksiyonel hataları
  waveform karşılaştırmasıyla yakalayıp düzelten Debug Agent

**Kritik mimari netliği:** MAGE 4 agent'a sahiptir — TBGenerator,
RTLGenerator, SimJudge, RTLEditor — ama bunların **hepsi tek bir LLM'i
paylaşır**. Beşinci component olan SimReviewer LLM kullanmaz, deterministik
bir iverilog/vvp wrapper'ıdır. Yani MAGE'in "multi-agent" niteliği
*model çoğulluğu* değil, **rol-temelli prompt specialization**'dır:
aynı LLM, dört farklı role-context ile çağrılır.

Bu mimari netliği orijinal projemizin temelini oluşturuyordu çünkü Plan v1
**MAGE'i agent-başına-farklı-LLM destekleyecek şekilde extend etmeyi**
hedefliyordu — fine-tuned vs base Qwen-7B karşılaştırmasını agent
roller seviyesinde yapmak için 4 senaryolu bir ablation çalışması:

| Senaryo | TB Agent | RTL Agent | Judge Agent | Debug Agent |
|---------|----------|-----------|-------------|-------------|
| S1 — Base-only | base | base | base | base |
| S2 — FT-only | FT | FT | FT | FT |
| S3 — Hybrid RTL | base | **FT** | base | base |
| S3b — Hybrid Debug | base | base | base | **FT** |

Bu ablation'ı koşturmak için MAGE'in tek-LLM mimarisini "agent başına
farklı LLM" mimarisine dönüştürmek gerekiyordu. Bunun için
**RoutingTokenCounter** patch'i tasarlandı (`patches/routing_token_counter.py`,
repoda hâlâ duruyor): her agent'ın `set_cur_tag(self.__class__.__name__)`
çağrısına bakıp doğru LLM endpoint'ini seçen bir TokenCounter subclass'ı.

### 1.2. Pivot — neden ve nasıl

T7 forensic raporu (Debug Agent live smoke test) kritik bir bulgu
çıkardı: **qwen2.5-coder:7b modeli MAGE'in Testbench Generator
aşamasında sistematik olarak takılıyor** — keyword halüsinasyonları
(`module` yerine `topmodule`) testbench'in compile olmasını
engelliyor, pipeline candidate generation veya Debug Agent branch'ine
hiç ulaşamıyor.

Bu durumda 4 senaryolu ablation **ölçülemez** çünkü:
- Karşılaştırmak istediğimiz mekanizmalar hiç çalışmıyor
- Pipeline assertion'a düşüp `is_pass=False` üretiyor
- Hangi senaryoda hangi agent'ın katkısının ne olduğunu izole edemiyoruz

**Pivot kararı (Plan v2):** Agent-başına-farklı-LLM ablation'ı bırak,
qwen2.5-coder:32b ile **MAGE methodology reproduction** çalışmasına dön.
Bu pivot iki şey değiştirdi:

1. **Mimari pivot:** "Agent başına farklı LLM" projesi → "Tek-LLM, tek
   model" projesi. RoutingTokenCounter patch'i hiç entegre edilmedi.
2. **Model pivot:** qwen2.5-coder:7b (+ FT) → qwen2.5-coder:32b (sadece base)

Sonuç olarak proje, bir **MAGE extension** girişimi olarak başladı,
bir **MAGE reproduction study** olarak kapandı. Yeni soru:
*"MAGE methodology'si daha küçük, açık kaynak, lokal bir modelle paperın
sonuçlarını ne kadar yeniden üretir?"*

### 1.3. Final bulgular

5 forensic task (T5–T9) sonunda projenin ürettiği üç bulgu var:

**Bulgu 1 (mühendislik): MAGE'in Claude'a-özel implicit varsayımları var.**
Beş ayrı yamada/teşhiste bunu belgeledik:

- **JSON parsing asymmetry** (T5 yaması): MAGE'in JSON output parser'ı
  yalnızca Vertex modelleri için fence-stripping yapıyordu. Claude saf
  JSON döndürdüğü için sorun çıkmıyor; Qwen ```` ```json ``` ```` fence
  ile sardığı için her parse fail oluyor. `json_mode=True` (Ollama
  grammar-constrained sampling) eklenmesi sorunu kaynağında çözdü:
  13 parse error → 0.

- **Stderr filtering brittleness** (T6 yaması): `sim_reviewer.py` benign
  warning listesi Claude'un ürettiği RTL stilini varsayıyordu. Qwen
  farklı port topology seçtiğinde iverilog "dangling input port" uyarısı
  atıyor, sim_reviewer bunu fail kabul ediyor. Functional olarak doğru
  çıktı yanlış sayılıyor. Whitelist genişletmesiyle çözüldü.

- **Silent exception handling** (T7'de teşhis edildi, yamalanmadı):
  `agent.py:253`'teki outer try/except, pipeline assertion'larını
  sessizce `is_pass=False`'a çeviriyor. "RTL fonksiyonel olarak yanlış"
  ile "pipeline crash" ayırt edilemez hale geliyor — pass rate metriği
  muğlaklaşıyor.

- **TB Gen brittleness on small models** (T7 bulgusu): 7B-class
  modellerin TB Gen aşamasında keyword halüsinasyonları (örn.
  `topmodule`) testbench'in compile olmasını engelliyor. Pipeline
  candidate generation branch'ine erişemiyor.

- **SimJudge verdict oscillation** (T9'da teşhis edildi, yamalanmadı):
  Aynı simülasyon verisi üzerinde SimJudge stochastic sampling
  nedeniyle bir "TB needs fix" bir "TB OK" verdict'i üretiyor. Bu
  oscillation `sim_max_retry=4` budget'ını tüketiyor, pipeline TB
  loop'unda sıkışıyor, RTLEditor branch'i hiç tetiklenemiyor.

**Bulgu 2 (ana sonuç): Debug Agent mekanizması açık modellerle doğal
olarak tetiklenmiyor.** 18 problem-run boyunca (T5×5 + T7×4 + T8×5 + T9×4,
örtüşmeler dahil), Debug Agent (RTLEditor) **tek bir round bile çalışmadı**.
Üç farklı root cause ortaya çıktı:

| Konfigürasyon | Tetiklenmeme nedeni | Kanıt |
|---|---|---|
| 7B kolay problemlerde | Initial RTL/TB tek shot'ta doğru → debug branch'e gerek yok | T5: 3/5 problem properly_finished |
| 7B zor problemlerde (kmap) | TB Gen halüsinasyon → assert → branch erişilemez | T7: 4/4 problem properly_finished_tag absent |
| 32B kolay problemlerde | Initial RTL/TB tek shot'ta doğru | T8: 4/5 problem properly_finished |
| **32B zor problemlerde (FSM)** | **SimJudge oscillation** — TB OK/fix verdict'i kararsız → loop kendini tutamıyor | **T9: 315 ve 83 mismatch'lik functionally-wrong RTL'lere rağmen 0 candidate, 0 editor round** |

T9'daki SimJudge oscillation bulgusu özellikle önemli çünkü bu **gerçek
bir pipeline design bug'ı** — model kapasitesi sorunu değil. Aynı
simulation verisine bakan SimJudge, sıcaklık-temelli sampling nedeniyle
bir TB'yi "fix gerek" sayıp bir "OK" sayıyor:

```
"tb_needs_fix": false
"tb_needs_fix": true     ← aynı veri, farklı verdict
"tb_needs_fix": false
"tb_needs_fix": true
"tb_needs_fix": false
"tb_needs_fix": false
```

**Bu observation'a mimari netlik açısından önemli bir not:** SimJudge ve
RTLEditor MAGE'in tek-LLM mimarisinde **aynı modeli paylaşır**. Yani
bir agent'ın stochastic davranışı diğerinin verdict'ini etkiler.
Paper'ın Claude implementation'ı bu sorunla karşılaşmamış olabilir
çünkü Claude 3.5 Sonnet'in long-context reasoning consistency'si
qwen2.5-coder:32b'ye kıyasla yüksek. Açık modellerle reproduction
yaparken Judge agent için temperature=0 sampling önerilir — ama bu
mevcut MAGE pipeline'ında parametrize edilmemiş.

**Bulgu 3 (capability): qwen2.5-coder:32b basit problemlerde Claude
benzeri performans gösteriyor.** T8'de 5/5 pass aldı (T5'in 7B json_mode
sonucundan 3/5 → 5/5). 7B'nin tıkandığı problemler (Prob001 zero,
Prob004 vector2) 32B'de tek shot'ta doğru üretildi. Ama bu pass'ler
**MAGE methodology'sinin değil, sadece initial RTL kalitesinin
sonucu** — sistem zaten Debug Agent'ı kullanmadan çalışıyor.

### 1.4. Bilimsel katkı

Bu projenin orijinal hipotezi (FT vs base ablation) test edilemedi
çünkü test edilmesi için gereken pipeline mekanizması (Debug Agent)
açık modellerle aktive edilemedi. Ama proje farklı, daha değerli bir
katkı üretti:

> **MAGE methodology'si reproducible değil, en azından mevcut
> implementation'ı ile.** Pipeline'ın headline mekanizmaları (Debug
> Agent, candidate generation) Claude 3.5 Sonnet'in spesifik output
> davranışlarına bağımlı bir kontrol akışının gerisinde duruyor. Bu
> bağımlılıklar paper'da rapor edilmemiş; biz forensic task serisiyle
> üçünü yamaladık (JSON parser asymmetry, stderr filtering) ve ikisini
> teşhis edip dokümente ettik (silent exception handling, SimJudge
> verdict oscillation).

Bu negative finding, methodology yayınlarının açık modellerle
reproducibility'sinin nasıl test edilmesi gerektiği konusunda da bir
örnek oluşturuyor.

---

## 2. Tez / rapor yapısı önerisi

Aşağıdaki iskelet, projenin gerçek seyrini akademik yazıma dökmek için
optimize edilmiş. Pivot'u gizlemek yerine bir araştırma keşfi olarak
sunar — Pozisyon A doğrultusunda.

### 2.1. İskelet (örnek bölüm sırası)

**Bölüm 1 — Giriş**
- LLM-temelli RTL üretiminin önemi
- Multi-agent yaklaşımların ortaya çıkışı
- MAGE paper'ının pozisyonu ve katkısı
- Claude bağımlılığı ve açık model reproducibility'si problemi
- Bu çalışmanın araştırma sorusu (orijinal: ablation; revize: reproduction)

**Bölüm 2 — Background**
- LLM-temelli HDL üretim literatürü (paper'ın kendi kaynaklarından)
- VerilogEval benchmark
- **MAGE'in 4-agent mimarisi — kritik netleştirme** (TBGen, RTLGen,
  Judge, Debug + SimReviewer):
  - 4 LLM agent rol-temelli prompt specialization ile **tek bir LLM'i
    paylaşır**
  - SimReviewer LLM-bazlı değil, deterministik (iverilog wrapper)
  - "Multi-agent" terimi MAGE'de model çoğulluğu değil rol çoğulluğu
- High-temperature sampling ve state checkpoint mekanizması

**Bölüm 3 — Metodoloji**
- 3.1. **Plan v1 — Orijinal hipotez:** FT vs base ablation, agent
  başına farklı LLM (4 senaryo)
- 3.2. Plan v1'in mimari extension'ı: RoutingTokenCounter patch
  tasarımı, agent-class-temelli LLM dispatch
- 3.3. Hardware ve model setup
- 3.4. Forensic task serisi: T0–T9 sıralaması
- 3.5. **Pivot kararı (Plan v2):** T7 sonucu, mimari pivot (multi-LLM
  → single-LLM), model pivot (7B+FT → 32B reproduction)
- 3.6. RoutingTokenCounter'ın hiç entegre edilmemesinin gerekçesi

**Bölüm 4 — Bulgular**
- 4.1. Engineering bulguları (JSON parser asymmetry, stderr filter,
  silent except)
- 4.2. Debug Agent activation analysis
  - Three+ root causes: TB Gen failure, single-shot success, judge
    oscillation
  - Quantitative: 0 rounds across 18 problem-runs
- 4.3. Capability bulguları (32B'nin pass rate'i, Claude ile kıyas)
- 4.4. SimJudge oscillation derin analizi (Prob127 case study)
  - Lemmings RTL'i, 83 mismatch, judge verdict sequence
  - Bu paper'ın Fig 3 case study'sinin ters analoğu
  - Tek-LLM mimarisinin oscillation'a katkısı (judge ve editor aynı
    LLM'i paylaşır → stochastic noise hem verdict hem fix'i etkiler)

**Bölüm 5 — Tartışma**
- 5.1. Methodology reproducibility'si: hangi mekanizmaları
  doğrulayabildik, hangilerini doğrulayamadık
- 5.2. MAGE'in Claude-bağımlılıklarının kaynağı: implicit assumptions
- 5.3. Açık modeller için ne gerekli: prompt rewriting, judge
  determinism, exception surfacing
- 5.4. Tek-LLM mimarisinin avantajları ve dezavantajları (proje
  bağlamında değerlendirme)
- 5.5. Negative finding'in değeri ve genelleştirilebilirliği

**Bölüm 6 — Sonuç ve gelecek çalışmalar**
- Özet
- Gelecek çalışma önerileri:
  - Judge agent için lower-temperature sampling
  - TB Gen bypass modu (golden TB only)
  - Surfaced exception logging
  - Açık model için prompt template revizyonu
  - **RoutingTokenCounter'ın gerçek devreye girmesi** (uygun
    benchmark seçildiğinde Plan v1 ablation'ı tamamlanabilir)

**Ekler**
- A. Detaylı patch listesi (T5, T6 diff'leri)
- B. RoutingTokenCounter tasarım belgesi (entegre edilmemiş ama
  hazır kod)
- C. Forensic task raporları (T5–T9 DONE/BLOCKED dosyaları)
- D. Tüm 9 problem-run'ın per-problem log özetleri
- E. Repo bağlantısı ve reproducibility instructions

### 2.2. Rapor yazımı için pratik notlar

**Pivot'u sun, gizleme.** Proje akademik dürüstlük açısından çok güçlü
bir pozisyonda — pivot kararı ve onun gerekçesi rapor metodolojisinin
bir parçası. "Önce X yapmaya çalıştık, neden çalışmadığını X kanıtla
belgeledik, sonra Y'ye döndük" anlatısı methods chapter'da olduğu gibi
verilmeli.

**MAGE'in mimari netliğini Bölüm 2'de yerleştir.** "Multi-agent" terimi
yanıltıcı — paper bunu "1 LLM, 4 role" olarak kullanıyor ama bu
literature'da yaygın bir muğlaklık. Senin tezin, projeye başlarken bu
terimi nasıl yorumlayıp Plan v1'i nasıl tasarladığınızı ve sonra
gerçek uygulamada bu yorumu nasıl revize ettiğinizi netleştirmeli.

**SimJudge oscillation'ı thesis'in core findings'i yap.** Bu bulgu hem
paperın yapmadığı bir gözlem (paper kendi pipeline'ında bu sorunu
yaşamamış çünkü Claude'un determinism'i yüksek), hem de pratik bir
katkı (gelecekte MAGE benzer bir sistem çalıştıracak araştırmacılar
için uyarı). T9'daki Prob127 case study'sini paper'ın Fig 3'ünün
analoğu olarak göster — paper "checkpoint Debug Agent'ı çalıştırıyor"u
gösteriyor, sen "checkpoint'e ulaşılamıyor"u gösteriyorsun.

**Quantitative özet ön plana çıkar.**
- 18 problem-run × 0 Debug Agent round = mekanizma %0 aktivasyon
- 13 → 0 JSON parse error (T5)
- 1/5 → 5/5 pass rate (T5 7B vs T8 32B)
- 4 farklı root cause for non-activation, 1 yeni keşfedilen design bug
- 2 patch entegre, 2 patch teşhis edildi-edilmedi, 1 mimari extension
  tasarlandı-edilmedi

**Limitations'a dürüst yaklaş.** Ablation hedeflenmiş ama tamamlanmamış.
Sample size küçük (en fazla 5 problem). Tek model ailesi (Qwen2.5).
Tek inference engine (Ollama). RoutingTokenCounter pratikte hiç test
edilmedi. Bunları açıkça yaz; gizlemeye çalışmak review'da çok daha
kötü olur.

### 2.3. Tahmini sayfa sayısı (TR/EN tez formatında)

- Bölüm 1: 4-6 sayfa
- Bölüm 2: 8-12 sayfa (mimari netleştirme nedeniyle biraz daha uzun)
- Bölüm 3: 12-15 sayfa (pivot anlatısı yer kaplar)
- Bölüm 4: 15-20 sayfa (en uzun, bulgular detaylı)
- Bölüm 5: 8-10 sayfa
- Bölüm 6: 3-4 sayfa
- Ekler: 12-18 sayfa
- **Toplam: 65-85 sayfa** — yüksek lisans tezi için uygun ölçek

---

## 3. İlerideki teknik adımlar (eğer projeyi devam ettirirsen)

Tez yazıldıktan sonra zamanın olursa:

### Düşük efor, yüksek değer
- **agent.py:253 silent except patch'i** — 5 satırlık değişiklik,
  pipeline crash'leri görünür yapar
- **SimJudge için temperature=0** — judge agent'ın oscillation'ı
  azalır, deterministic verdict üretir (T9 bulgusuna doğrudan çözüm)

### Orta efor
- **MAGE prompt'ları için Qwen-tuned varyant** — özellikle TB Gen
  prompt'ı, format example'larıyla zenginleştirilmiş
- **Debug Agent isolation test mode** — TB Gen'i bypass eden bir
  test modu, mekanizmanın gerçek capability'sini ölçer
- **RoutingTokenCounter'ı gerçekten devreye al** — Plan v1'in
  ablation'ını uygun problem seçimiyle tamamla (ama önce SimJudge
  ve TB Gen sorunları çözülsün)

### Yüksek efor
- **Full VerilogEval-v2 reproduction** — 156 problem × n=20, 8-15 saat
  RunPod, ~$50. Asıl pass rate sayısını üretir
- **Methodology comparison study** — MAGE + 5 farklı açık model,
  karşılaştırmalı reproducibility çalışması

### Akademik
- **Bu pivotu workshop paper'a çevirmek** — "Open-Model Reproducibility
  of Multi-Agent RTL Generation Systems: A Case Study on MAGE" gibi
  bir başlık. ICCAD-LAD veya MLCAD workshop'ları uygun

---

## 4. Repo durumu (kapanış zamanı)

GitHub: https://github.com/DerinVural/MAGE_Pipeline_Integration

| Branch | main |
|---|---|
| Commit count | 7 (initial + 6 task) |
| Last commit | `[T9] Add hard-problem runner...` (BLOCKED) |
| Patch summary (entegre) | T5 + T6 (2 source files modified, 1 test file added) |
| Patch summary (entegre değil) | RoutingTokenCounter (Plan v1 mimari extension'ı) |
| Reports | T5_DONE, T6_DONE, T7_DONE, T8_DONE, T9_BLOCKED |

Repo şu anda tezdeki "Methods" + "Results" bölümünü support eden tüm
artefaktları içeriyor. Reproducibility için yeterli (Ollama setup +
benchmark + runner scriptler hazır). RoutingTokenCounter `patches/`
altında durduğu için **gelecekte Plan v1 ablation'ı yapılmak istenirse
referans implementation hazır**.

---

## 5. PM kapanış notu

Bu proje "başarısız ablation çalışması" olarak değil, "**paper
methodology'sinin açık model reproducibility'sine dair forensic case
study + paper'da rapor edilmemiş design dependency'lerin sistematik
dokümantasyonu**" olarak değerlendirilmeli.

Pivot'un iki boyutu var ve ikisi de tez için değerli:

**Mimari boyut:** Plan v1 multi-LLM extension'ı tasarlandı (S1-S3b
ablation için), uygulanmadı, **çünkü altta yatan tek-LLM pipeline
açık modellerle bile çalışmıyor**. Önce tek-LLM çalışsın, sonra
multi-LLM extension'ı düşünülür.

**Model boyutu:** 7B+FT yerine 32B base, çünkü 7B mekanizmaları
tetikleyemiyor.

T7 verdict γ ve T9 verdict η birlikte okunduğunda, MAGE'in Claude-a
özel implicit dependency'leri olduğunu beş ayrı kanıt katmanıyla
belgeliyor:

1. JSON parser asymmetry (T5 — yamalandı)
2. Stderr filter assumption (T6 — yamalandı)
3. TB Gen brittleness on small models (T7 — teşhis)
4. Silent exception masking (T7 — teşhis)
5. Judge agent verdict oscillation (T9 — teşhis)

Bunlar paperda rapor edilmemiş. Senin katkın bunları belgeleyip
ölçmek. Akademik hikaye temiz: hipotez kuruldu, mimari extension
tasarlandı, test edilemedi, neden test edilemediği derinlemesine
analiz edildi, beş bulgu çıktı.

Tez yazımında başarılar — sorularına cevap vermek için yanındayım.
