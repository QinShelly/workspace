
--delete from ppdai

--delete from bidProcess

select * from ppdai

select * from bidProcess

select bidProcess.id,processFlag,amount_bid 
from bidProcess 
join vw_ppdai on bidProcess.id = vw_ppdai.id 


select amount_bid from vw_ppdai 
where id = 'http://invest.ppdai.com/loan/info?id=33710278'

select insert_dt,* 
from vw_clean_ppdai
--where id = 'http:	//invest.ppdai.com/loan/info?id=33908001'
where amount_bid > 0
order by insert_dt desc

select * from vw_ppdai
where education_level = '本科'
and education_method = '普通' and wsl_rank < 150
and title not like '%闪电%'
order by insert_dt desc

