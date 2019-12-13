drop table #TMP
SELECT GETDATE() AS payloadTime,
'a7a850f1-e4b9-4b51-9d56-67a4a192a98e' payloadID, 
'application/json' as payloadContentType,
'urn:ibm:ift:payload:type:json:triple'payloadTypeURI,
'urn:ibm:ift:product:lot:class:78612067.LvgQ.90361t' as epc,
'[{"key": "title", "value": "Payload Cosecha", "type": "string"}, {"key": "Piscina", "value": "92", "type": "string"}, {"key": "Comida", "value": "BALANCEADO", "type": "string"} ]' as payload
INTO #TMP



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
            
      </ift:payload>')
FROM
(
      select (SELECT payloadTime,payloadID,payloadContentType,payloadTypeURI,epc,payload
                  FROM #TMP D
                  FOR XML PATH('payloadMessage'), ROOT('ift:payload'), type ) XmlStructure
) x
