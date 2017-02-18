
--delete from ppdai

--delete from bidProcess

select * from bidProcess
order by insert_dt desc

select bidProcess.id,bidProcess.insert_dt,processFlag,bid 
from bidProcess 
join vw_clean_ppdai on bidProcess.id = vw_clean_ppdai.id 
order by bidProcess.insert_dt desc


select insert_dt,* 
from vw_clean_ppdai
--where id = 'http:	//invest.ppdai.com/loan/info?id=33908001'
where bid > 0
order by insert_dt desc

select insert_dt,* from vw_clean_ppdai
where id = 'http://invest.ppdai.com/loan/info?id=33898445'

select * from vw_ppdai
where education_level = '本科'
and education_method = '普通' and wsl_rank < 150
and title not like '%闪电%'
order by insert_dt desc

