
--exec sp_ArriboPlantaIBM '93033','S 2210','5277','indu-01-09102019'

alter PROCEDURE sp_ArriboPlantaIBM
@numlot numeric,  
@embfactura varchar(10),  
@producto varchar(10),
@LoteArribo varchar(100)
AS  
BEGIN  

set dateformat ymd
------***********PARA PRUEBAS************
-- drop table #tmp,#TMPDATOS  
--declare @numlot numeric  
--declare @embfactura varchar(10)  
--declare @producto varchar(10)
--declare @parentID varchar(50)
--declare @LoteArribo varchar(20)

--SET @numlot = 92007
--SET @embfactura= 'S 1789'
--SET @producto = '5277'
--SET @parentID = 'urn:ibm:ift:lpn:obj:78612067.147232'
----SET @LoteArribo = 'Lebama-36-181222019'
----***********FIN PARA PRUEBAS************
--select * from tb_uuidGen where  uid_lote = 91873
declare @uuid varchar(255)
declare @prefijo varchar(255)
declare @guitra varchar(25)
exec fun_retornauuid @numlot,@producto ,@embfactura,'2019','ARP',null,@uuid out
set @prefijo = (select pre_preprefix+''+pre_prempresa from tb_prefijosIBM where pre_codigo = 1)
set @guitra = (select rlo_guitra from tb_reglot where  rlo_numero =  @numlot )

SELECT clp_nomcom,gtr_RecepFechaHoraLlegada,convert(varchar(10),gtr_RecepFechaHoraLlegada,111)+' '+ convert(varchar(8),gtr_RecepFechaHoraLlegada,108) + '.100' HoraLlega,rlo_recibi Recibidas,'LBS' med_abrev,clp_codigo
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
GROUP BY clp_nomcom,gtr_RecepFechaHoraLlegada,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+@LoteArribo,med_abrev,clp_codigo,rlo_recibi;



 select STUFF(CONVERT(VARCHAR(50), CAST((select HoraLlega from #TMPDATOS) AS DATETIMEOFFSET), 127),20,8,'')AS eventTime  
 ,'-05:00' as eventTimeZoneOffset  
 , @uuid eventID,  
 'DELETE' as [action]
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as id  
  ,'urn:epcglobal:cbv:sdt:owning_party' as [source/@type]  
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro =  (select clp_codigo from #TMPDATOS )) as [source],  
 'urn:epcglobal:cbv:sdt:owning_party' as [destination/@type]  
 ,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as destination
 , 'urn:epcglobal:cbv:bizstep:LLegadaPlanta' as bizstep,
 @prefijo + '.' + @guitra  as parentID
 into #tmp;  

 --insert into tb_instalacionesIBM values (188,'INDUCAM','urn:ibm:ift:location:loc:78612067.jqdc')
 --select * from tb_instalacionesIBM
 --SELECT * FROM tb_provee where clp_nomcom like '%INDUCAM%'



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
								   {$y/eventID}
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
      select (SELECT eventTime,eventTimeZoneOffset,eventID,id,[action],bizStep, [source/@type]
	  , [source], [destination/@type],destination,parentID,
	   (select  Detalle epcClass,Recibidas quantity, med_abrev uom from #TMPDATOS  for xml path, type) as childQuantityList
                  FROM #TMP D
                  FOR XML PATH('EPCISBody'), ROOT('ns3:EPCISDocument'), type ) XmlStructure 
) x 

   

End 
Go