SET DATEFORMAT YMD
--DROP TABLE #TMP01 
SELECT tcd_lote,rlo_noguia, clp_nomcom,clp_CertificINP,rlo_piscin, RLO_FECHA, rlo_recibi, rlo_netas,RLO_ROMANE,  SUM(tcd_cantid) CAJAS, SUM(tcd_cantid/emb_cantid) MASTER, SUM(tcd_cantid*emb_peso*med_factor) LIBRAS
--INTO #TMP01
FROM TB_TRACAMAUTO 
INNER JOIN TB_TRACADAUTO ON trc_numsec= TCD_NUMERO AND tcd_produc= '5277'
INNER JOIN tb_reglot ON rlo_numero = tcd_lote
INNER JOIN tb_guitra ON gtr_numero = rlo_guitra 
INNER JOIN tb_provee ON clp_codigo= gtr_codpro
INNER JOIN TB_PRODUC ON pro_codcor = tcd_produc
INNER JOIN tb_Embala ON emb_codigo= PRO_EMBALA
INNER JOIN tb_medida ON med_codigo= PRO_UNIMED
WHERE trc_tipo = 'EX' AND trc_embfactura= 'S 1322' AND trc_Fecha>='2019/01/01' --and tcd_lote = 91539
GROUP BY tcd_lote,RLO_NOGUIA,clp_nomcom,clp_CertificINP,rlo_piscin, RLO_FECHA, rlo_recibi, rlo_netas, rlo_romane

SELECT * FROM #TMP01

SELECT lid_lote,  SUM(lid_canenv) , SUM(lid_canenv/emb_cantid), SUM(lid_canenv*emb_peso*med_factor)
FROM #TMP01
INNER JOIN tb_liqtun ON liq_lote = tcd_lote
INNER JOIN tb_litund ON liq_numero = lid_numero AND lid_lote = tcd_lote AND lid_produc= 4997
INNER JOIN TB_PRODUC ON pro_codcor = lid_produc
INNER JOIN tb_Embala ON emb_codigo = pro_embala
INNER JOIN tb_medida ON med_codigo = pro_unimed
GROUP BY lid_lote

SELECT  LIQ_TUNPLA,LIQ_CIETUN,  SUM(lid_canenv) , SUM(lid_canenv/emb_cantid), SUM(lid_canenv*emb_peso*med_factor)
FROM #TMP01
INNER JOIN tb_liqtun ON liq_lote = tcd_lote
INNER JOIN tb_litund ON liq_numero = lid_numero AND lid_lote = tcd_lote AND lid_produc= 4997
INNER JOIN TB_PRODUC ON pro_codcor = lid_produc
INNER JOIN tb_Embala ON emb_codigo = pro_embala
INNER JOIN tb_medida ON med_codigo = pro_unimed
INNER JOIN Tb_CieTun ON ctu_numero = LIQ_CIETUN
GROUP BY liq_tunpla,LIQ_CIETUN

SELECT * FROM TB_CIETUN

SELECT LIQ_CIETUN FROM tb_liqtun 
INNER JOIN Tb_CieTun ON ctu_numero = LIQ_CIETUN

SELECT * 
FROM tb_litVAd 
INNER JOIN tb_liqvag ON liq_numero = lid_numero 
WHERE lid_produc = '5305'
