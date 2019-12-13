
----####EVENTO LLEGADA A PLANTA AggregationEvent
--drop table #TMP
--SELECT GETDATE() AS eventTime,'-05:00' as eventTimeZoneOffset,
--'urn:uuid:e8fd4fe9-3283-40ec-ad28-0a35a3300d42' EventID, 
--'urn:ibm:ift:lpn:obj:78612067.08032019-05-pallet'parentID,
--'DELETE' as [action],'urn:ibm:ift:location:loc:78612067.IRud' id
--INTO #TMP


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
      </ns3:EPCISDocument>')
FROM
(
      select (SELECT eventTime,eventTimeZoneOffset,EventID,parentID,[action],id,'urn:epcglobal:cbv:sdt:owning_party' as [source/@type],'urn:ibm:ift:location:loc:78612067.laag' as [source],'urn:epcglobal:cbv:sdt:owning_party' as [destination/@type],'urn:ibm:ift:location:loc:78612067.IRud' as destination,
	   (select 'urn:ibm:ift:product:lot:class:78612067.QnyE.08032019-05' as epcClass,54464 quantity,'LBR' uom for xml path, type) as childQuantityList
                  FROM #TMP D
                  FOR XML PATH('EPCISBody'), ROOT('ns3:EPCISDocument'), type ) XmlStructure
) x
