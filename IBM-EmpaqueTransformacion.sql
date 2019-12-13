
--exec sp_EmpaqueClasifIBM  '93183','S 2210','4997' 

alter PROCEDURE sp_EmpaqueClasifIBM
@numlot numeric,  
@embfactura varchar(10),  
@producto varchar(10)  
AS  
BEGIN 

--'90361','S 0790','5277' 

SET DATEFORMAT YMD


declare @fechadate datetime
declare @fecha VARCHAR(250)
SET @fecha = ''
declare @congelar varchar(255)
set @congelar = ''
declare @uuid varchar(255)
exec fun_retornauuid @numlot,@producto ,@embfactura,'2019','EMC',null,@uuid out


SELECT clp_nomcom,gtr_RecepFechaHoraLlegada,rlo_netas Recibidas,'LBS' med_abrev,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+convert(varchar(20),tcd_lote) as Detalle
INTO #TMPLLEGA
FROM TB_TRACAMAUTO 
INNER JOIN TB_TRACADAUTO ON trc_numsec= TCD_NUMERO AND tcd_produc= @producto
INNER JOIN tb_reglot ON rlo_numero = tcd_lote
INNER JOIN tb_guitra ON gtr_numero = rlo_guitra 
INNER JOIN tb_provee ON clp_codigo= gtr_codpro
INNER JOIN TB_PRODUC ON pro_codcor = tcd_produc
INNER JOIN tb_Embala ON emb_codigo= PRO_EMBALA
INNER JOIN tb_medida ON med_codigo= PRO_UNIMED
inner join tb_productosIBM on pro_codcor = pri_codcor
WHERE trc_tipo = 'EX' AND trc_embfactura= @embfactura AND trc_Fecha>='2019/01/01' and tcd_lote = @numlot
GROUP BY  clp_nomcom,gtr_RecepFechaHoraLlegada,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+convert(varchar(20),tcd_lote),med_abrev,clp_codigo,rlo_netas;





--SELECT  convert(numeric(18,2),SUM(tcd_cantid*emb_peso*med_factor)) LIBRAS,'LBR' med_abrev,clp_codigo
--,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),tcd_lote) as Detalle
--INTO #TMPDATOS
--FROM TB_TRACAMAUTO 
--INNER JOIN TB_TRACADAUTO ON trc_numsec= TCD_NUMERO AND tcd_produc= @producto
--INNER JOIN tb_reglot ON rlo_numero = tcd_lote
--INNER JOIN tb_guitra ON gtr_numero = rlo_guitra 
--INNER JOIN tb_provee ON clp_codigo= gtr_codpro
--INNER JOIN TB_PRODUC ON pro_codcor = tcd_produc
--INNER JOIN tb_Embala ON emb_codigo= PRO_EMBALA
--INNER JOIN tb_medida ON med_codigo= PRO_UNIMED
--inner join tb_productosIBM on pro_codcor = pri_codcor
--WHERE trc_tipo = 'EX' AND trc_embfactura= @embfactura AND trc_Fecha>='2019/01/01' and tcd_lote = @numlot
--GROUP BY tcd_lote,RLO_NOGUIA,clp_codigo,clp_nomcom,clp_CertificINP,rlo_piscin, RLO_FECHA, rlo_recibi, rlo_netas, rlo_romane
--,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),tcd_lote),med_abrev,clp_codigo


select convert(numeric(18,2),SUM(lid_canenv *emb_peso* med_factor)) LIBRAS,'LBR' med_abrev,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),lid_lote) as Detalle
into #DATAFINAL
from tb_liqtun
inner join tb_litund on liq_numero = lid_numero
INNER JOIN tb_reglot ON rlo_numero = lid_lote
INNER JOIN tb_guitra ON gtr_numero = rlo_guitra 
INNER JOIN tb_provee ON clp_codigo= gtr_codpro
INNER JOIN TB_PRODUC ON pro_codcor = lid_produc
INNER JOIN tb_Embala ON emb_codigo= PRO_EMBALA
INNER JOIN tb_medida ON med_codigo= PRO_UNIMED
inner join tb_productosIBM on pro_codcor = pri_codcor
where lid_lote = @numlot and lid_produc = @producto
group by med_abrev,med_factor,emb_peso,clp_codigo,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),lid_lote)
union all 
select  convert(numeric(18,2),SUM(lid_canenv *emb_peso* med_factor)) LIBRAS,'LBR' med_abrev,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),lid_lote) as Detalle
from  tb_liqvag 
inner join tb_litvad on  liq_numero = lid_numero
INNER JOIN tb_reglot ON rlo_numero = lid_lote
INNER JOIN tb_guitra ON gtr_numero = rlo_guitra 
INNER JOIN tb_provee ON clp_codigo= gtr_codpro
INNER JOIN TB_PRODUC ON pro_codcor = lid_produc
INNER JOIN tb_Embala ON emb_codigo= PRO_EMBALA
INNER JOIN tb_medida ON med_codigo= PRO_UNIMED
inner join tb_productosIBM on pro_codcor = pri_codcor
where lid_lote = @numlot and lid_produc = @producto
and liq_estado <> 'AN' and liq_tipo <>'RE'
group by med_abrev,med_factor,emb_peso,clp_codigo,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),lid_lote)





select @congelar =  dpr_codigo from tb_produc
inner join tb_detproces on dpr_codigo = pro_congela
 where pro_codcor = @producto
 if (@congelar = '25' or @congelar =  '1')
 begin

 set @fecha = (select top 1  convert(varchar(10),liq_datcre,111)+' '+ convert(varchar(8),liq_datcre,108) + '.100' as trc_fecha
					from tb_liqtun
					inner join tb_litund on liq_numero = lid_numero
					where lid_lote = @numlot and lid_produc = @producto and liq_estado = 'AC'
					order by liq_datcre asc)

	
 end
 else
 begin

 set @fecha = (select top 1  convert(varchar(10),liq_datcre,111)+' '+ convert(varchar(8),liq_datcre,108) + '.100' as liq_datcre
					from tb_liqvag
					inner join tb_litvad on liq_numero = lid_numero
					where lid_lote = @numlot and lid_produc = @producto and liq_estado = 'AC'
					order by liq_datcre asc)
	set @fecha = (select dbo.restahoraFechaIBM (@fecha,'00:40:05'))
	set @fechadate = CONVERT(datetime,@fecha)
	set @fecha = (select convert(varchar(10),@fechadate,111)+' '+ convert(varchar(8),@fechadate,108) + '.100')
 
 end




select STUFF(CONVERT(VARCHAR(50), CAST(@fecha AS DATETIMEOFFSET), 127),20,8,'')AS eventTime
,'-05:00' as eventTimeZoneOffset
,@uuid eventID,  
'urn:ibm:ift:lpn:obj:78612067.08032019-05-pallet'parentID
,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as id
 ,'urn:epcglobal:cbv:sdt:owning_party' as [source/@type]
,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as [source],
'urn:epcglobal:cbv:sdt:owning_party' as [destination/@type]
,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as destination
,'urn:epcglobal:cbv:bizstep:EmpaqueTrans'  bizStep
into #TMP;


WITH XMLNAMESPACES(N'urn:epcglobal:epcis:xsd:1' as ns3,N'urn:epcglobal:cbv:mda' as ns2, '1.2' AS schemaVersion, '2019-08-29T17:17:52.988Z' AS creationDate)
SELECT XmlStructure.query('
   for $x in /ns3:EPCISDocument return
      <ns3:EPCISDocument schemaVersion="1.2" creationDate="2019-08-29T17:17:52.988Z" xmlns:ns2="urn:epcglobal:cbv:mda" xmlns:ns3="urn:epcglobal:epcis:xsd:1">
         <EPCISBody>
               <EventList>
				<extension>
                       
         {
         for $y in $x/EPCISBody return
                  <TransformationEvent>
								   {$y/eventTime}
								   {$y/eventTimeZoneOffset}
								   {$y/bizStep}
								   <baseExtension>
								   {$y/eventID}
								   </baseExtension>
                                   <inputQuantityList>
                        {for $f in $y/inputQuantityList/row return
                             <quantityElement>
								   {$f/epcClass}
                                   {$f/quantity}
								   {$f/uom}
                              </quantityElement>      
                        }
						</inputQuantityList>

						 <outputQuantityList>
                        {for $r in $y/outputQuantityList/row return
                             <quantityElement>
								   {$r/epcClass}
                                   {$r/quantity}
								   {$r/uom}
                              </quantityElement>      
                        }
						</outputQuantityList>
						<bizLocation>
							{$y/id}
						</bizLocation>
						<extension>
						<sourceList>
							  {$y/source}

                        </sourceList>
                       <destinationList>
                              {$y/destination}
                        </destinationList>
						<ilmd>
							 {$y/bestBeforeDate}
							 {$y/itemExpirationDate}
							 {$y/sellByDate}
						</ilmd>

						</extension>                 
                  
                                   </TransformationEvent>
         }
				</extension>  
               </EventList>
            </EPCISBody>
      </ns3:EPCISDocument>') as XMLA
FROM
(
      select (SELECT eventTime,eventTimeZoneOffset,eventID,id,bizStep, [source/@type],
	  [source], [destination/@type], destination
	  ,'2019-10-18T00:00:00Z' as bestBeforeDate
	  ,'2019-10-18T00:00:00Z' as itemExpirationDate
	  ,'2019-10-18T00:00:00Z' as sellByDate,
	   (select Detalle as epcClass,Recibidas quantity,'LBR' uom from #TMPLLEGA for xml path, type) as inputQuantityList,
	   (select  Detalle epcClass,LIBRAS quantity, med_abrev uom from #DATAFINAL for xml path, type) as outputQuantityList
                  FROM #TMP D
                  FOR XML PATH('EPCISBody'), ROOT('ns3:EPCISDocument'), type ) XmlStructure
) x

end

