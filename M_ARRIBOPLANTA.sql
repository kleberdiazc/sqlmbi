
--exec sp_ArriboPlantaIBM '91728','S 1789','5277','urn:ibm:ift:lpn:obj:78612067.147232','Lebama-36-01092019'

alter PROCEDURE sp_ArriboPlantaIBM
@numlot numeric,  
@embfactura varchar(10),  
@producto varchar(10),
@parentID varchar(50),
@LoteArribo varchar(20)
AS  
BEGIN  

----***********PARA PRUEBAS************
 drop table #tmp,#TMPDATOS  
declare @numlot numeric  
declare @embfactura varchar(10)  
declare @producto varchar(10)
declare @parentID varchar(50)
declare @LoteArribo varchar(20)

SET @numlot = 92025
SET @embfactura= 'S 1789'
SET @producto = '5277'
SET @parentID = 'urn:ibm:ift:lpn:obj:78612067.147232'
--SET @LoteArribo = 'Lebama-36-01092019'
----***********FIN PARA PRUEBAS************

declare @uiid varchar(2555)

SELECT clp_nomcom,gtr_RecepFechaHoraLlegada,rlo_recibi Recibidas,'LBS' med_abrev,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+@LoteArribo as Detalle
INTO #TMPDATOS
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
GROUP BY  clp_nomcom,gtr_RecepFechaHoraLlegada,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+@LoteArribo,med_abrev,clp_codigo,rlo_recibi;

 select STUFF(CONVERT(VARCHAR(50), CAST((select gtr_RecepFechaHoraLlegada from #TMPDATOS) AS DATETIMEOFFSET), 127),20,8,'')AS eventTime  
 ,'-05:00' as eventTimeZoneOffset  
 , EventID,  
 'DELETE' as [action]
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as id  
  ,'urn:epcglobal:cbv:sdt:owning_party' as [source/@type]  
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro =  (select clp_codigo from #TMPDATOS )) as [source],  
 'urn:epcglobal:cbv:sdt:owning_party' as [destination/@type]  
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as destination
 , 'urn:epcglobal:cbv:bizstep:LLegadaPlanta' as bizstep,
 @parentID as parentID
 into #tmp;  



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
								   {$y/bizStep}
								   <baseExtension>
								   {$y/EventID}
								   </baseExtension>
								   {$y/parentID}
								   <childEPCs/>
								    {$y/action}
								   <bizLocation>
										{$y/id}
								   </bizLocation>
								   <extension>
                                   <childQuantityList>
                        {for $f in $y/childQuantityList/row return
                             <quantityElement>
								   {$f/epcClass}
                                   {$f/quantity}
								   {$f/uom}
                              </quantityElement>      
                        }
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
      select (SELECT eventTime,eventTimeZoneOffset,EventID,id,[action],bizStep, [source/@type]
	  , [source], [destination/@type],destination,parentID,
	   (select  Detalle epcClass,Recibidas quantity, med_abrev uom from #TMPDATOS  for xml path, type) as childQuantityList
                  FROM #TMP D
                  FOR XML PATH('EPCISBody'), ROOT('ns3:EPCISDocument'), type ) XmlStructure 
) x 

   

End 
Go