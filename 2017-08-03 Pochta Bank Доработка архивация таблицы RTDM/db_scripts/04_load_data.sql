 
 insert /*+ APPEND */ into CDM.RTDM_CLIENT_APPLICATION
 (APPLICATION_ID,CLIENT_CD,INTERACTION_ID,DECISION_DTTM,DECISION_ID,REQUEST_DTTM,INT_STATUS,SEGMENT_CD,RTDM_QUERY_XML,REQUESTED_LIMIT,REQUESTED_TERM,RTDM_RESPONSE_XML,CAMPAIGN_CD,REQUEST_ID)
 select APPLICATION_ID,CLIENT_CD,INTERACTION_ID,DECISION_DTTM,DECISION_ID,REQUEST_DTTM,INT_STATUS,SEGMENT_CD,RTDM_QUERY_XML,REQUESTED_LIMIT,REQUESTED_TERM,RTDM_RESPONSE_XML,CAMPAIGN_CD,REQUEST_ID 
 from CDM.RTDM_CLIENT_APPLICATION_BKP 
 where  REQUEST_DTTM >= TO_DATE('2017-02-01 00:00:00','SYYYY-MM-DD HH24:MI:SS') 
 and REQUEST_DTTM is not null;
commit;

 insert /*+ APPEND */ into CDM.RTDM_CLIENT_APPLICATION_ARCH 
   (APPLICATION_ID
                        ,CLIENT_CD
                        ,INTERACTION_ID
                        ,DECISION_DTTM
                        ,DECISION_ID
                        ,REQUEST_DTTM
                        ,INT_STATUS
                        ,SEGMENT_CD
                        ,RTDM_QUERY_XML_PRODUCT2CODE
                        ,RTDM_QUERY_XML_CHANNEL
                        ,REQUESTED_LIMIT
                        ,REQUESTED_TERM
                        ,RTDM_RESPONSE_XML
                        ,CAMPAIGN_CD
                        ,REQUEST_ID )
                        select 
                            APPLICATION_ID
                            ,CLIENT_CD
                            ,INTERACTION_ID
                            ,DECISION_DTTM
                            ,DECISION_ID
                            ,REQUEST_DTTM
                            ,INT_STATUS
                            ,SEGMENT_CD
                            ,SUBSTR(RTDM_QUERY_XML
                                    ,INSTR(RTDM_QUERY_XML,'<atc:Product2Code>')+length('<atc:Product2Code>')
                                    ,INSTR(RTDM_QUERY_XML,'</atc:Product2Code>')-INSTR(RTDM_QUERY_XML,'<atc:Product2Code>') - length('<atc:Product2Code>')) as RTDM_QUERY_XML_Product2Code
                            ,SUBSTR(RTDM_QUERY_XML
                                    ,INSTR(RTDM_QUERY_XML,'<atc:Channel>')+length('<atc:Channel>')
                                    ,INSTR(RTDM_QUERY_XML,'</atc:Channel>')-INSTR(RTDM_QUERY_XML,'<atc:Channel>') - length('<atc:Channel>')) as RTDM_QUERY_XML_CHANNEL  
                            ,REQUESTED_LIMIT
                            ,REQUESTED_TERM
                            ,SUBSTR(RTDM_RESPONSE_XML
                            ,INSTR(RTDM_RESPONSE_XML,'<NS1:PRODUCT_C>')+length('<NS1:PRODUCT_C>')
                            ,INSTR(RTDM_RESPONSE_XML,'</NS1:PRODUCT_C>')-INSTR(RTDM_RESPONSE_XML,'<NS1:PRODUCT_C>') - length('<NS1:PRODUCT_C>')) as RTDM_RESPONSE_XML 
                            ,CAMPAIGN_CD
                            ,REQUEST_ID
  from CDM.RTDM_CLIENT_APPLICATION_BKP 
 where  REQUEST_DTTM < TO_DATE('2017-02-01 00:00:00','SYYYY-MM-DD HH24:MI:SS') 
 and REQUEST_DTTM is not null;
commit;