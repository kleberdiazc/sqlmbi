
-- =============================================  
-- Author:  <kleber Diaz>  
-- Create date: <21/10/2019>  
-- Description: <agregacion LLEgada a Planta,>  
-- =============================================  
  
--exec sp_ObservacionCongelar '84827','S 2210','4997' 
ALTER PROCEDURE sp_ObservacionCongelar 
@numlot numeric,  
@embfactura varchar(10),  
@producto varchar(10)  
AS  
BEGIN  


SET DATEFORMAT YMD

declare @fechadate datetime
declare @fecha VARCHAR(250)
SET @fecha = ''
declare @congelar varchar(255)
set @congelar = ''
declare @uuid varchar(255)
exec fun_retornauuid @numlot,@producto ,@embfactura,'2019','CGL',null,@uuid out


--SELECT  convert(numeric(18,2),SUM(tcd_cantid*emb_peso*med_factor)) LIBRAS,'LBR' med_abrev,clp_codigo
--,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),tcd_lote) as Detalle
----,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),tcd_lote) as DetalleMaster
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
--,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),tcd_lote),med_abrev,clp_codigo;
----pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),tcd_lote)


select convert(numeric(18,2),SUM(lid_canenv *emb_peso* med_factor)) LIBRAS,'LBR' med_abrev,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),lid_lote) as Detalle
into #TMPDATOS
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
inner join tb_lototr on lot_numero = lid_lote
inner join tb_tiplot on lot_tiplot = tip_codigo
where lid_lote = @numlot and lid_produc = @producto
and liq_estado <> 'AN' and tip_codigo in ('CAM','R1')
group by med_abrev,med_factor,emb_peso,clp_codigo,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix+'.'+convert(varchar(20),lid_lote)



select dpr_codigo from tb_produc
inner join tb_detproces on dpr_codigo = pro_congela
 where pro_codcor = @producto
 if (@congelar  = '25' or @congelar  = '1')
 begin
	set @fecha = (select top 1 convert(varchar(10),ctu_fechor,111)+' '+ convert(varchar(8),ctu_fechor,108) + '.100' AS  ctu_fechor 
					from tb_liqtun
					inner join tb_litund on liq_numero = lid_numero
					inner join tb_cietun on liq_cietun = ctu_numero
					where liq_lote = @numlot and lid_produc = @producto and liq_estado <> 'AN'
					order by ctu_fechor asc)	
 end
 else
 begin
	set @fecha = (select top 1  convert(varchar(10),trc_fecha,111)+' '+ convert(varchar(8),trc_fecha,108) + '.100' as trc_fecha
					from tb_tracadauto
					inner join tb_tracamauto on trc_numsec = tcd_numero
					inner join tb_bodega on bod_codigo= trc_codcam and bod_categ ='tu'
					where tcd_lote=@numlot and tcd_produc =@producto and trc_ingegr='I' and trc_estado <> 'AN'
					order by trc_fecha asc)
	set @fecha = (select dbo.restahoraFechaIBM (@fecha,'00:30:05'))
	set @fechadate = CONVERT(datetime,@fecha)
	set @fecha = (select convert(varchar(10),@fechadate,111)+' '+ convert(varchar(8),@fechadate,108) + '.100')
 end


--IF NOT EXISTS (SELECT * FROM #fecha ) 
--BEGIN
--	insert into #fecha values(CONVERT(datetime,'2019/01/01 10:00:00'))
--END

 select STUFF(CONVERT(VARCHAR(50), CAST( @fecha AS DATETIMEOFFSET), 127),20,8,'')AS eventTime  
	 ,'-05:00' as eventTimeZoneOffset  
	 ,@uuid eventID,
	 'OBSERVE' as [action]
	 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as id  
	  ,'urn:epcglobal:cbv:sdt:owning_party' as [source/@type]  
	 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as [source],  
	 'urn:epcglobal:cbv:sdt:owning_party' as [destination/@type]  
	 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as destination
	 , 'urn:epcglobal:cbv:bizstep:Congelacion' as bizstep
	 into #tmp;  


 
WITH XMLNAMESPACES(N'urn:epcglobal:epcis:xsd:1' as ns3,N'urn:epcglobal:cbv:mda' as ns2, '1.2' AS schemaVersion, '2019-08-29T17:17:52.988Z' AS creationDate)
SELECT XmlStructure.query('
   for $x in /ns3:EPCISDocument return
      <ns3:EPCISDocument schemaVersion="1.2" creationDate="2019-08-29T17:17:52.988Z" xmlns:ns2="urn:epcglobal:cbv:mda" xmlns:ns3="urn:epcglobal:epcis:xsd:1">
         <EPCISBody>
               <EventList>
                       
         {
         for $y in $x/EPCISBody return
                  <ObjectEvent>
								   {$y/eventTime}
								   {$y/eventTimeZoneOffset}
								   {$y/bizStep}
								   <baseExtension>
								   {$y/eventID}
								   </baseExtension>
								   <epcList />
								    {$y/action}
								   <bizLocation>
										{$y/id}
								   </bizLocation>
								   <extension>
                                   <quantityList>
                        {for $f in $y/quantityList/row return
                             <quantityElement>
								   {$f/epcClass}
                                   {$f/quantity}
								   {$f/uom}
                              </quantityElement>      
                        }
						</quantityList>
						<sourceList>
							  {$y/source}

                        </sourceList>
                       <destinationList>
                              {$y/destination}
                        </destinationList>


						</extension>                 
                  
                    </ObjectEvent>
         }
				</EventList>
            </EPCISBody>
      </ns3:EPCISDocument>') as XMLA
FROM
(
      select (SELECT eventTime,eventTimeZoneOffset,eventID,id,[action],bizStep,[source/@type],[source], [destination/@type] ,[destination],
	   (select Detalle as epcClass,LIBRAS quantity,med_abrev uom from #TMPDATOS for xml path, type) as quantityList
                  FROM #TMP D
                  FOR XML PATH('EPCISBody'), ROOT('ns3:EPCISDocument'), type ) XmlStructure
) x

end 
go