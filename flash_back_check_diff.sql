-- пример как найти отличия между тем что было и тем что стало

select pattern_nm from CDM.dict_offer_pattern 
minus
select pattern_nm from CDM.dict_offer_pattern  as of  TIMESTAMP  TO_TIMESTAMP('2017-10-13 09:30:00', 'YYYY-MM-DD HH:MI:SS');