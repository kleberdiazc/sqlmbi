-- exec sp_payLoadDetalleMaster  91989,'S 2210','5277'


alter PROCEDURE sp_payLoadDetalleMaster
@numlot numeric,  
@embfactura varchar(10),  
@producto varchar(10)
AS
BEGIN  

set dateformat ymd

declare @uuid varchar(255)
declare @congelar varchar(255)
set @congelar = ''
declare @fechadate datetime
declare @fecha VARCHAR(250)
SET @fecha = ''

exec fun_retornauuid @numlot,@producto ,@embfactura,'2019','PLM',null,@uuid out

SELECT pro_desesp,tal_descri,rlo_netas,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),tcd_lote) as Detalle
INTO #TMPDATOS2
FROM TB_TRACAMAUTO 
INNER JOIN TB_TRACADAUTO ON trc_numsec= TCD_NUMERO AND tcd_produc= @producto
INNER JOIN tb_reglot ON rlo_numero = tcd_lote
INNER JOIN tb_guitra ON gtr_numero = rlo_guitra 
INNER JOIN tb_provee ON clp_codigo= gtr_codpro
INNER JOIN TB_PRODUC ON pro_codcor = tcd_produc
INNER JOIN tb_Embala ON emb_codigo= PRO_EMBALA
INNER JOIN tb_medida ON med_codigo= PRO_UNIMED
inner join tb_productosIBM on pro_codcor = pri_codcor
inner join tb_tallas on tal_codigo = tcd_codtal
WHERE trc_tipo = 'EX' AND trc_embfactura= @embfactura AND trc_Fecha>='2019/01/01' and tcd_lote = @numlot
GROUP BY pro_desesp,tal_descri,rlo_netas,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),tcd_lote),clp_codigo;

declare @descrip varchar(100)
declare @talla varchar(20)
declare @netas numeric

select @descrip = pro_desesp,@talla =tal_descri,@netas = rlo_netas from #TMPDATOS2

select @congelar =  dpr_codigo from tb_produc
inner join tb_detproces on dpr_codigo = pro_congela
 where pro_codcor = @producto
 if (@congelar <> '25' or @congelar <> '1')
 begin
	set @fecha = (select top 1 convert(varchar(10),trc_fecha,111)+' '+ convert(varchar(8),trc_fecha,108) + '.100' AS  trc_fecha  
	from tb_tracadauto
	inner join tb_tracamauto on trc_numsec = tcd_numero
	inner join tb_bodega on bod_codigo= trc_codcam and bod_categ ='tu'
	where tcd_lote=@numlot and tcd_produc =@producto and trc_ingegr='I'
	order by trc_fecha asc)
 end
 else
 begin
	set @fecha = (select top 1  convert(varchar(10),trc_fecha,111)+' '+ convert(varchar(8),trc_fecha,108) + '.100' AS  trc_fecha  
	from tb_tracadauto
	inner join tb_tracamauto on trc_numsec = tcd_numero
	inner join tb_bodega on bod_codigo= trc_codcam and bod_categ ='tu'
	where tcd_lote=@numlot and tcd_produc =@producto and trc_ingegr='T'
	order by trc_fecha asc)
 end





select STUFF(CONVERT(VARCHAR(70), CAST(@fecha AS DATETIMEOFFSET), 127),20,8,'')AS payloadTime,
 @uuid payloadID, 
'application/json' as payloadContentType,
'urn:ibm:ift:payload:type:json:triple'payloadTypeURI,
(select Detalle from #TMPDATOS2 ) as epc,
'[{"key": "title", "value": "Detalle Master", "type": "string"}, {"key": "Marca", "value": "' + @descrip + '", "type": "string"},
{"key": "Talla", "value": "' + @talla + '", "type": "string"},{"key": "KGBrutos", "value":"' + convert(varchar(50),@netas) + '", "type": "string"}]' as payload
into #tmp;



WITH XMLNAMESPACES(N'urn:ibm:ift:xsd:1' as ift)
SELECT XmlStructure.query('
   for $x in /ift:payload return
      <ift:payload>
                            
         {
         for $y in $x/payloadMessage return
					<payloadMessage>    
								   {$y/payloadID}
								   {$y/payloadTime}
								   {$y/payloadContentType}
								   {$y/payloadTypeURI}
								   <epcList>
								       {$y/epc}
								   </epcList>
								   {$y/payload}
								 </payloadMessage>
         }
            
      </ift:payload>') As XMLA
FROM
(
      select (SELECT payloadTime,payloadID,payloadContentType,payloadTypeURI,epc,payload
                  FROM #TMP D
                  FOR XML PATH('payloadMessage'), ROOT('ift:payload'), type ) XmlStructure
) x
END
go