 --exec sp_ObservacionEnvioBodegaa '93183','S 2210','4997' 
 alter PROCEDURE sp_ObservacionEnvioBodegaa
@numlot numeric,  
@embfactura varchar(10),  
@producto varchar(10)  
AS  
BEGIN  
 --drop table #tmp  
 --insert into #tmp 
 set dateformat ymd 

 declare @uuid varchar(255)
 declare @fechaBodega datetime
exec fun_retornauuid @numlot,@producto ,@embfactura,'2019','OEB',null,@uuid out

set @fechaBodega = (select top 1 tb_tracamsscc.trc_fecha
from tb_tracamauto
inner join tb_tracadauto on trc_numsec = tcd_numero
inner join tb_tracamsscc on tb_tracamsscc.trc_numtra = tb_tracamauto.trc_numsec
where tcd_lote = @numlot  and tcd_produc = @producto and trc_proconver = 'Pallets'
order by tb_tracamsscc.trc_datecrea asc)


select STUFF(CONVERT(VARCHAR(50), CAST( @fechaBodega AS DATETIMEOFFSET), 127),20,8,'')AS eventTime  
 ,'-05:00' as eventTimeZoneOffset  
 ,@uuid eventID,  
 'OBSERVE' as [action]
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as id  
  ,'urn:epcglobal:cbv:sdt:owning_party' as [source/@type]  
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as [source],  
 'urn:epcglobal:cbv:sdt:owning_party' as [destination/@type]  
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as destination
 , 'urn:epcglobal:cbv:bizstep:EnvioBodega' as bizstep
 into #tmp;  


--SELECT SUM(tcd_cantid/emb_cantid) MASTEER,'EA' med_abrev,clp_codigo
--,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),tcd_lote) as Detalle
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
--GROUP BY pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),tcd_lote),med_abrev,clp_codigo;

select convert(numeric(18,2),SUM(lid_canenv/emb_cantid)) MASTEER,'EA' med_abrev,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),lid_lote) as Detalle
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
and liq_estado <> 'AN' 
group by med_abrev,med_factor,emb_peso,clp_codigo,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),lid_lote)
union all 
select convert(numeric(18,2),SUM(lid_canenv/emb_cantid)) MASTEER,'EA' med_abrev,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),lid_lote) as Detalle
from tb_liqvag
inner join tb_litvad on liq_numero = lid_numero
INNER JOIN tb_reglot ON rlo_numero = lid_lote
INNER JOIN tb_guitra ON gtr_numero = rlo_guitra 
INNER JOIN tb_provee ON clp_codigo= gtr_codpro
INNER JOIN TB_PRODUC ON pro_codcor = lid_produc
INNER JOIN tb_Embala ON emb_codigo= PRO_EMBALA
INNER JOIN tb_medida ON med_codigo= PRO_UNIMED
inner join tb_productosIBM on pro_codcor = pri_codcor
where lid_lote = @numlot and lid_produc = @producto
and liq_estado <> 'AN' and liq_tipo <> 'RE'
group by med_abrev,med_factor,emb_peso,clp_codigo,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),lid_lote);





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
      select (SELECT eventTime,eventTimeZoneOffset,eventID,id,[action],bizStep, [source/@type]
	  , [source], [destination/@type],destination,
	   (select  Detalle epcClass,MASTEER quantity, med_abrev uom from #TMPDATOS  for xml path, type) as quantityList
                  FROM #TMP D
                  FOR XML PATH('EPCISBody'), ROOT('ns3:EPCISDocument'), type ) XmlStructure
) x

End 
Go