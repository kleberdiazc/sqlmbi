 --exec sp_PayLoadPlanta '92007','S 1789','5277','2019' 

 alter PROCEDURE sp_PayLoadPlanta
@numlot numeric,  
@embfactura varchar(10),  
@producto varchar(	10),
@anio varchar(10)
AS  
BEGIN  
 --drop table #tmp  
 --insert into #tmp  
  declare @cadenanumfact varchar(20)          
  declare @trc_codcam varchar(2)          
  declare  @trc_numsec numeric  
  declare @temperatura varchar(20)
  declare @fechaBodega datetime
  declare @uuid varchar(255)

	exec fun_retornauuid @numlot,@producto ,@embfactura,'2019','PLP',null,@uuid out


  set @fechaBodega = (select top 1 tb_tracamsscc.trc_fecha
  from tb_tracamauto
  inner join tb_tracadauto on trc_numsec = tcd_numero
  inner join tb_tracamsscc on tb_tracamsscc.trc_numtra = tb_tracamauto.trc_numsec
  where tcd_lote = @numlot  and tcd_produc = @producto and tb_tracamauto.trc_ingegr = 'E' AND tb_tracamauto.trc_tipo = 'EX'
  order by tb_tracamsscc.trc_datecrea asc)


  set @temperatura = ''

  select @temperatura = emp_temper from Tb_EmbarqueProd where emp_factura = @embfactura and emp_anio = @anio and emp_estado <> 'AN'

  SELECT @trc_codcam= trc_codcam, @trc_numsec = trc_numsec          
  FROM TB_TRACAMAUTO         
  WHERE trc_embfactura = @embfactura and year(trc_fecha) = @anio and trc_estado = 'AC' --trc_fecha>= @anio+'/01/01'  and trc_estado = 'AC' 
	and trc_tipo = 'EX'       
          
          
  SELECT TCD_SSCC, TCD_UBICBARORIG,@trc_numsec trc_numsec          
  into #tempo1          
  FROM TB_TRACAmSSCC           
  INNER JOIN TB_TRACADSSCC ON TRC_NUMSEC = TCD_NUMERO          
  inner join tb_cabsscc on sscc_numero = tcd_sscc AND SSCC_BODEGA =@trc_codcam  and TCD_UBICBARORIG = sscc_ubicacion  
  WHERE TRC_CAMDES= @trc_codcam AND TRC_FECHA < (SELECT TRC_DATECREA FROM TB_TRACAMAUTO WHERE TRC_NUMSEC = @trc_numsec)          
  AND TRC_DATECREA>= isnull((SELECT MAX(TRC_DATECREA) FROM TB_TRACAMAUTO WHERE TRC_CODCAM = @trc_codcam AND TRC_INGEGR = 'E' AND trc_estado <> 'AN' and TRC_DATECREA <(SELECT TRC_DATECREA FROM TB_TRACAMAUTO WHERE TRC_NUMSEC = @trc_numsec)),'2019/01/01')
  group by TCD_SSCC, TCD_UBICBARORIG
  ORDER BY  TCD_UBICBARORIG, TCD_SSCC 
  
  
  SELECT DISTINCT TCD_SSCC Pallet,(SELECT COUNT(*) FROM tb_detsscc dssccPalletdet where dssccPalletdet.DSSCC_SSCC = TCD_SSCC) quantity,
  pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),dssccMaster.DSSCC_LOTE) as Detalle,pai_descri
  into #Datos2
  FROM #tempo1
  INNER JOIN tb_cabsscc on sscc_numero =  TCD_SSCC
  inner join tb_detsscc dssccPallet on DSSCC_SSCC = sscc_numero
  inner join tb_cabsscc ssccMaster on ssccMaster.sscc_numero = dssccPallet.DSSCC_NUMERO
  inner join tb_detsscc dssccMaster on dssccMaster.DSSCC_SSCC = ssccMaster.sscc_numero
 inner join tb_productosIBM on ssccMaster.SSCC_CodProd = pri_codcor
 inner join tb_produc on pro_codcor = convert(varchar(25),pri_codcor)
 inner join tb_pais on pai_codigo = pro_destino
   WHERE dssccMaster.DSSCC_LOTE = @numlot


select STUFF(CONVERT(VARCHAR(50), CAST(@fechaBodega AS DATETIMEOFFSET), 127),20,8,'')AS payloadTime,
@uuid payloadID, 
'application/json' as payloadContentType,
'urn:ibm:ift:payload:type:json:triple'payloadTypeURI,
'urn:ibm:ift:lpn:obj:'+'78612067.'+(select dbo.fun_prefix(Pallet))  as epc,
'[{"key": "title", "value": "Payload Camaron en Planta", "type": "string"},
 {"key": "Pais Destino", "value": "'+ RTRIM(LTRIM(pai_descri)) +'", "type": "string"},
 {"key": "Temp Promedio", "value": "'+@temperatura+'", "type": "string"},
 {"key": "SSP", "value": "xxxx-xxxx-xxxx", "type": "string"}]' as payload
INTO #TMP
from #Datos2;



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
            
      </ift:payload>') as XMLA
FROM
(
      select (SELECT payloadTime,payloadID,payloadContentType,payloadTypeURI,epc,payload
                  FROM #TMP D
                  FOR XML PATH('payloadMessage'), ROOT('ift:payload'), type ) XmlStructure
) x
END
Go