 --exec sp_EnvioClienteIBM '90963','S 1322','5277','2019' 
 alter PROCEDURE sp_EnvioClienteIBM
@numlot numeric,  
@embfactura varchar(10),  
@producto varchar(10),
@anio varchar(10)
AS  
BEGIN  
 --drop table #tmp  
 --insert into #tmp  

 ----***********PARA PRUEBAS************
-- drop table #tempo1,#Datos2,#Datos3
--declare @numlot numeric  
--declare @embfactura varchar(10)  
--declare @producto varchar(10)
--declare @parentID varchar(50)
--declare @LoteArribo varchar(20)
--declare @anio varchar(20)

--SET @numlot = 92025
--SET @embfactura= 'S 1789'
--SET @producto = '5277'
--SET @parentID = 'urn:ibm:ift:lpn:obj:78612067.147232'
--SET @anio = '2019'
--SET @LoteArribo = 'Lebama-36-01092019'
----***********FIN PARA PRUEBAS************



  declare @cadenanumfact varchar(20)          
  declare @trc_codcam varchar(2)          
  declare  @trc_numsec numeric
  declare @fechaBodega datetime

	set @fechaBodega = (select top 1 tb_tracamsscc.trc_datecrea
	from tb_tracamauto
	inner join tb_tracadauto on trc_numsec = tcd_numero
	inner join tb_tracamsscc on tb_tracamsscc.trc_numtra = tb_tracamauto.trc_numsec
	where tcd_lote = @numlot  and tcd_produc = @producto and tb_tracamauto.trc_ingegr = 'E' AND tb_tracamauto.trc_tipo = 'EX'
	order by tb_tracamsscc.trc_datecrea asc)



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
  pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),dssccMaster.DSSCC_LOTE) as Detalle
  into #Datos2
  FROM #tempo1
  INNER JOIN tb_cabsscc on sscc_numero =  TCD_SSCC
  inner join tb_detsscc dssccPallet on DSSCC_SSCC = sscc_numero
  inner join tb_cabsscc ssccMaster on ssccMaster.sscc_numero = dssccPallet.DSSCC_NUMERO
  inner join tb_detsscc dssccMaster on dssccMaster.DSSCC_SSCC = ssccMaster.sscc_numero
 inner join tb_productosIBM on ssccMaster.SSCC_CodProd = pri_codcor
  WHERE dssccMaster.DSSCC_LOTE = @numlot
																											
  select 'urn:ibm:ift:lpn:obj:'+'78612067.'+(select dbo.fun_prefix(Pallet)) as PalletD,quantity,Detalle,STUFF(CONVERT(VARCHAR(50), CAST(@fechaBodega AS DATETIMEOFFSET), 127),20,8,'')AS eventTime  
  ,'-05:00' as eventTimeZoneOffset,
 'ADD' as [action]
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as id  
  ,'urn:epcglobal:cbv:sdt:owning_party' as [source/@type]  
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as [source],  
 'urn:epcglobal:cbv:sdt:owning_party' as [destination/@type]  
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as destination
 , 'urn:epcglobal:cbv:bizstep:EnvioCliente' as bizstep
   into #Datos3
   from #Datos2;

 alter table #Datos3 add eventID varchar(255)


declare @uuid varchar(255)
SET NOCOUNT ON;  
  
DECLARE @PalletD varchar(255) 
DECLARE vendor_cursor CURSOR FOR   
SELECT PalletD 
FROM #Datos3;  
  
OPEN vendor_cursor  
  
FETCH NEXT FROM vendor_cursor   
INTO @PalletD
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
    

	exec fun_retornauuid @numlot,@producto ,@embfactura,'2019','ECL',@PalletD, @uuid out
	update #Datos3 set eventID = @uuid where PalletD = @PalletD

    FETCH NEXT FROM vendor_cursor   
    INTO @PalletD 
END   
CLOSE vendor_cursor;  
DEALLOCATE vendor_cursor;


 --,(select pre_preprefix+''+pre_prempresa+'.'+ @embfactura from tb_prefijosIBM where pre_codigo = 2) bizTransaction
 --,'urn:epcglobal:cbv:btt:po' as [bizTransaction/@type]

declare @bitz varchar(250)
declare @tipo varchar(250)

 set @bitz = (select pre_preprefix+''+pre_prempresa+':'+ rtrim(ltrim(@embfactura)) as bizTransaction
 from tb_prefijosIBM 
 where pre_codigo = 2)

 set @tipo = 'urn:epcglobal:cbv:btt:po'


 select @bitz as bizTransaction
 ,@tipo as [bizTransaction/@type]
 into #bizTransactionList;


--insert into #bizTransactionList
-- select pre_preprefix+''+pre_prempresa+':'+ 'PL3354' as bizTransaction
-- ,'urn:epcglobal:cbv:btt:desadv' as [bizTransaction/@type]
-- from tb_prefijosIBM 
-- where pre_codigo = 2;



WITH XMLNAMESPACES(N'urn:epcglobal:epcis:xsd:1' as ns3,N'urn:epcglobal:cbv:mda' as ns2, '1.2' AS schemaVersion, '2019-08-29T17:17:52.988Z' AS creationDate)
SELECT XmlStructure.query('
   for $x in /ns3:EPCISDocument return
      <ns3:EPCISDocument schemaVersion="1.2" creationDate="2019-08-29T17:17:52.988Z" xmlns:ns2="urn:epcglobal:cbv:mda" xmlns:ns3="urn:epcglobal:epcis:xsd:1">
         <EPCISBody>
               <EventList>                      
         {
         for $y in $x/EPCISBody return
                  <AggregationEvent>
								   {$y/eventTime}
								   {$y/eventTimeZoneOffset}
								   <baseExtension>
								   {$y/eventID}
								   </baseExtension>
								   {$y/bizStep}
								   {$y/parentID}
								   <childEPCs/>
								   {$y/action}
								   <bizLocation>
										{$y/id}
								   </bizLocation>
								   {for $r in $y/bizTransactionList/row return
								      <bizTransactionList>
										{$r/bizTransaction}
									  </bizTransactionList>
									}
									<extension>
									<childQuantityList>
										 <quantityElement>
											   {$y/epcClass}
											   {$y/quantity}
											   {$y/uom}
										  </quantityElement>      
									</childQuantityList>
									<sourceList>
										  {$y/source}
									</sourceList>
								   <destinationList>
										  {$y/destination}
									</destinationList>

									</extension>                 
                  
                    </AggregationEvent>
         }
       
               </EventList>
            </EPCISBody>
      </ns3:EPCISDocument>') as XMLA
FROM
(
      select (SELECT eventTime,eventTimeZoneOffset,eventID as eventID,id,[action],bizStep, [source/@type]
				, [source], [destination/@type],destination,quantity,'EA' uom,PalletD as parentID, Detalle as epcClass,
				 (select [bizTransaction/@type],bizTransaction from #bizTransactionList for xml path, type) as bizTransactionList
                  FROM #Datos3 D
                  FOR XML PATH('EPCISBody'), ROOT('ns3:EPCISDocument'), type ) XmlStructure
) x
End