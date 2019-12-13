-- =============================================    
-- Author:  <kleber Diaz>    
-- Create date: <21/10/2019>    
-- Description: <agregacion LLEgada a Planta,>    
-- =============================================    
    
--exec sp_LoteSongaIBM '91539','S 1756','4057','Lebama-36-181222019'    

alter PROCEDURE sp_LoteSongaIBM  
@numlot numeric,    
@embfactura varchar(10),    
@producto varchar(10),
@LoteArribo varchar(100)
AS    
BEGIN    
  
SET DATEFORMAT YMD  

declare @uuid varchar(255)
exec fun_retornauuid @numlot,@producto ,@embfactura,'2019','LTS',null,@uuid out

SELECT clp_nomcom,gtr_RecepFechaHoraLlegada,rlo_recibi Recibidas,'LBS' med_abrev,clp_codigo
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+ @LoteArribo as Detalle
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
GROUP BY  clp_nomcom,gtr_RecepFechaHoraLlegada,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+@LoteArribo,med_abrev,clp_codigo,rlo_recibi;






--DROP TABLE #TMPDATOS,#TMP  
SELECT rlo_netas,'LBS' med_abrev,clp_codigo,rlo_datcre  
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+convert(varchar(20),tcd_lote) as Detalle  
--,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),tcd_lote) as DetalleMaster  
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
GROUP BY tcd_lote,RLO_NOGUIA,clp_codigo,clp_nomcom,clp_CertificINP,rlo_piscin, RLO_FECHA, rlo_recibi, rlo_netas, rlo_romane  
,pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_llega+'.'+convert(varchar(20),tcd_lote),med_abrev,clp_codigo,rlo_datcre;  
--pri_cadenaUrn+pri_prefijoSonga+'.'+pri_prefix_master+'.'+convert(varchar(20),tcd_lote)  
  




  
select STUFF(CONVERT(VARCHAR(50), CAST((select rlo_datcre from #TMPDATOS) AS DATETIMEOFFSET), 127),20,8,'')AS eventTime  
,'-05:00' as eventTimeZoneOffset  
,@uuid eventID,  
'urn:ibm:ift:lpn:obj:78612067.08032019-05-pallet'parentID,  
'DELETE' as [action]  
,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as id  
 ,'urn:epcglobal:cbv:sdt:owning_party' as [source/@type]  
,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = (select clp_codigo from #TMPDATOS )) as [source],  
'urn:epcglobal:cbv:sdt:owning_party' as [destination/@type]  
,(select ibm_prefix from tb_instalacionesIBM where ibm_codpro = 0) as destination 
,'urn:epcglobal:cbv:bizstep:LoteSonga'  bizStep 
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
           <childEPCs/>  
           {$y/action}  
                                   
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
       select (SELECT eventTime,eventTimeZoneOffset,eventID,parentID,[action],id,[source/@type],[source],[destination/@type],destination, bizStep,   
    (select Detalle as epcClass, Recibidas quantity,'LBR' uom from #TMPLLEGA for xml path, type) as inputQuantityList,  
    (select Detalle as epcClass, rlo_netas quantity, med_abrev uom from #TMPDATOS uom for xml path, type) as outputQuantityList  
                  FROM #TMP D  
                  FOR XML PATH('EPCISBody'), ROOT('ns3:EPCISDocument'), type ) XmlStructure  
) x  
end