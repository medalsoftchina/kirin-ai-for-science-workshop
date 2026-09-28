# data/omics — データ取得元 (SOURCE)

Day2 Lab 2 (Foundry IQ ナレッジベース) 用の公開オミックスデータセット。
取得日: **2026-09-27**

## 1. Lactiplantibacillus plantarum 耐酸性に関する論文 (オープンアクセス)

### plantarum_acid_resistance_1.pdf
- タイトル: Research on the Potential Mechanism of Guanine Nucleotides Enhancing the Tolerance of *Lactiplantibacillus plantarum* Y12
- 誌: Foods (MDPI), DOI: 10.3390/foods15122244, PMCID: PMC13297897
- 取得元: https://mdpi-res.com/d_attachment/foods/foods-15-02244/article_deploy/foods-15-02244.pdf
- Europe PMC 検索: https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=%22Lactiplantibacillus%20plantarum%22%20AND%20%22acid%20tolerance%22%20AND%20OPEN_ACCESS:y
- 内容: GMP (グアニル酸) による L. plantarum Y12 の耐酸性向上メカニズム (トランスクリプトーム解析)

### plantarum_acid_resistance_2.pdf
- タイトル: Isolation and characterization of *Lactobacillus plantarum* LP2301 from bovine milk: acid and bile tolerance, antibacterial...
- 誌: npj Science of Food, DOI: 10.1038/s41538-026-00908-2, PMCID: PMC13490509
- 取得元: https://www.nature.com/articles/s41538-026-00908-2.pdf
- 内容: 牛乳由来 L. plantarum LP2301 の耐酸性 (pH 2.5)・耐胆汁酸性・抗菌活性の評価

## 2. clinvar_subset.csv (NCBI ClinVar サブセット, 160行)

- 取得方法: NCBI E-utilities (レート制限遵守: 0.4秒間隔, 3 req/sec 未満)
  - esearch: `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=clinvar&retmode=json&retmax=40&term=<GENE>[gene] AND ("pathogenic"[Clinical_Significance] OR "likely pathogenic"[Clinical_Significance] OR "benign"[Clinical_Significance] OR "likely benign"[Clinical_Significance])`
  - esummary: `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=clinvar&retmode=json&id=<ids>`
- 対象遺伝子 (各20件): BRCA1, BRCA2, TP53, EGFR, KRAS, ALK, MLH1, MSH2
- フィルタ: 単一遺伝子の変異のみ (巨大CNVを除外)、germline classification が
  Pathogenic / Likely pathogenic / Benign / Likely benign のもの
- 内訳: Pathogenic 23, Likely pathogenic 31, Benign 1, Likely benign 105
- 列: variation_id, gene, variant_name, clinical_significance, review_status, condition

※ ClinVar は日々更新されるため、再取得すると内容が変わる場合があります。

## 3. キリン研究領域に沿ったオープンアクセス論文 PDF x10 (papers/)

Day1 デモ / Day2 Lab 2 (Foundry IQ ナレッジベース) 用。全件 Europe PMC で
`OPEN_ACCESS:y` (CC BY 系ライセンス) を確認済み。取得日: **2026-09-28**
検証: `file` コマンドで PDF 判定 + 100KB 超 + PyMuPDF で 1 ページ目のタイトル照合。

### papers/lc_plasma_ifna_pdc_mechanism.pdf 【LC-Plasma / pDC】
- タイトル: *Lactococcus lactis* Strain Plasma Uniquely Induces IFN-α Production via Plasmacytoid Dendritic Cells
- 著者/年: Fujimura S, Kawamura M, Tamura Y. (2025)
- 誌: Microorganisms (MDPI), DOI: 10.3390/microorganisms13102261, PMCID: PMC12566558
- 取得元: https://mdpi-res.com/d_attachment/microorganisms/microorganisms-13-02261/article_deploy/microorganisms-13-02261-v2.pdf
- ライセンス: CC BY 4.0
- 関連性: LC-Plasma (JCM 5805) が pDC 経由で IFN-α を誘導するメカニズム論文。キリン免疫研究の中核。

### papers/lc_plasma_pdc_common_infections.pdf 【LC-Plasma / 臨床】
- タイトル: *Lactococcus lactis* strain Plasma activates plasmacytoid dendritic cells and mitigates common cold-like symptoms in healthy adults: a meta-analysis of individual participant data
- 著者/年: Kato Y, Kobayashi K, Kuramochi Y, Miyata T, Ushida Y, Hayamizu K. (2025)
- 誌: Frontiers in Immunology, DOI: 10.3389/fimmu.2025.1696989, PMCID: PMC12631266
- 取得元: https://www.frontiersin.org/journals/immunology/articles/10.3389/fimmu.2025.1696989/pdf
- ライセンス: CC BY 4.0
- 関連性: LC-Plasma の風邪様症状軽減を個別データメタ解析で示した臨床エビデンス。

### papers/lactobacilli_comparative_genomics_213.pdf 【乳酸菌ゲノミクス】
- タイトル: Expanding the biotechnology potential of lactobacilli through comparative genomics of 213 strains and associated genera
- 著者/年: Sun Z, Harris HMB, McCann A, et al. (2015)
- 誌: Nature Communications, DOI: 10.1038/ncomms9322, PMCID: PMC4667430
- 取得元: https://www.nature.com/articles/ncomms9322.pdf
- ライセンス: CC BY 4.0
- 関連性: 213 株の乳酸菌比較ゲノミクス。発酵・機能性素材の菌株探索の参照枠組み。

### papers/yeast_1011_genome_evolution.pdf 【酵母ゲノミクス】
- タイトル: Genome evolution across 1,011 *Saccharomyces cerevisiae* isolates
- 著者/年: Peter J, De Chiara M, Friedrich A, et al. (2018)
- 誌: Nature, DOI: 10.1038/s41586-018-0030-5, PMCID: PMC6784862
- 取得元: https://www.nature.com/articles/s41586-018-0030-5.pdf
- ライセンス: CC BY 4.0
- 関連性: 1,011 株の S. cerevisiae ゲノム進化解析。キリンの酵母ライブラリ研究に直結する大規模参照。

### papers/beer_yeast_domestication_divergence.pdf 【酵母 / 醸造オミクス】
- タイトル: Domestication and Divergence of *Saccharomyces cerevisiae* Beer Yeasts
- 著者/年: Gallone B, Steensels J, Prahl T, et al. (2016)
- 誌: Cell, DOI: 10.1016/j.cell.2016.08.020, PMCID: PMC5018251
- 取得元: https://biblio.ugent.be/publication/8173949/file/8173970.pdf (Ghent University Academic Bibliography)
- ライセンス: CC BY 4.0
- 関連性: 157 株のビール酵母のゲノム・表現型解析。醸造由来の酵母多様性と馴化の研究。

### papers/gut_microbiome_nuage_mediterranean_diet.pdf 【腸内マイクロバイオーム】
- タイトル: Mediterranean diet intervention alters the gut microbiome in older people reducing frailty and improving health status: the NU-AGE 1-year dietary intervention across five European countries
- 著者/年: Ghosh TS, Rampelli S, Jeffery IB, et al. (2020)
- 誌: Gut, DOI: 10.1136/gutjnl-2019-319654, PMCID: PMC7306987
- 取得元: https://ueaeprints.uea.ac.uk/id/eprint/74307/2/Published_Version.pdf (UEA Digital Repository)
- ライセンス: CC BY-NC 4.0
- 関連性: 食事介入が腸内マイクロバイオームと健康指標を改善するメタゲノム解析。ヘルスフーズ応用の範例。

### papers/fermented_foods_gut_microbiome.pdf 【腸内マイクロバイオーム / 発酵食品】
- タイトル: Fermented Foods, Health and the Gut Microbiome
- 著者/年: Leeuwendaal NK, Stanton C, O'Toole PW, Beresford TP. (2022)
- 誌: Nutrients (MDPI), DOI: 10.3390/nu14071527, PMCID: PMC9003261
- 取得元: https://mdpi-res.com/d_attachment/nutrients/nutrients-14-01527/article_deploy/nutrients-14-01527-v2.pdf
- ライセンス: CC BY 4.0
- 関連性: 発酵食品と腸内マイクロバイオーム・健康の関係のレビュー。発酵科学×腸内環境の橋渡し。

### papers/water_kefir_multiomics_fermented_food.pdf 【発酵食品マルチオミクス】
- タイトル: Water kefir as a paradigm for multi-omics and genome-scale metabolic modelling in fermented food
- 著者/年: Khan A, Breselge S, O'Mahony AK, et al. (2026)
- 誌: npj Biofilms and Microbiomes, DOI: 10.1038/s41522-026-00985-x, PMCID: PMC13260827
- 取得元: https://www.nature.com/articles/s41522-026-00985-x.pdf
- ライセンス: CC BY 4.0
- 関連性: 発酵食品へのマルチオミクス+ゲノムスケール代謝モデル適用の方法論レビュー。

### papers/fermented_milk_untargeted_metabolomics.pdf 【メタボロミクス / 発酵乳】
- タイトル: Untargeted Metabolomics and Physicochemical Analysis Revealed the Quality Formation Mechanism in Fermented Milk Inoculated with *Lactobacillus*
- 著者/年: Ao XL, Liao YM, Kang HY, et al. (2023)
- 誌: Foods (MDPI), DOI: 10.3390/foods12193704, PMCID: PMC10572762
- 取得元: https://mdpi-res.com/d_attachment/foods/foods-12-03704/article_deploy/foods-12-03704-v2.pdf
- ライセンス: CC BY 4.0
- 関連性: 発酵乳の非標的メタボロミクスによる品質形成機序解析。素材オミクス評価の実例。

### papers/lc_plasma_fatigue_immune_rct.pdf 【免疫栄養 / LC-Plasma RCT】
- タイトル: Effects of Ingesting Food Containing Heat-Killed *Lactococcus lactis* Strain Plasma on Fatigue and Immune-Related Indices after High Training Load: A Randomized, Double-Blind, Placebo-Controlled, Parallel-Group Trial
- 著者/年: Komano Y, Fukao K, Shimada K, et al. (2023)
- 誌: Nutrients (MDPI), DOI: 10.3390/nu15071754, PMCID: PMC10096552
- 取得元: https://mdpi-res.com/d_attachment/nutrients/nutrients-15-01754/article_deploy/nutrients-15-01754-v2.pdf
- ライセンス: CC BY 4.0
- 関連性: 加熱殺菌 LC-Plasma 摂取による疲労・免疫指標改善の RCT。免疫栄養の臨床応用例。

※ 当初選定した 2 件 (Nature Microbiol 2021 ケフィア論文 PMC7610452、JISSN 2018
LC-Plasma 運動免疫 RCT PMC6090876) は出版社側のボット対策で PDF を取得できず、
同テーマの取得可能な OA 論文 (上記 npj / Nutrients) に差し替えた。
