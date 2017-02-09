
delete 	from ppdai

delete from bidProcess

select * from ppdai

select * from bidProcess

select bidProcess.id,amount_bid from bidProcess 
join vw_ppdai on bidProcess.id = vw_ppdai.id 
where processFlag is null and amount_bid > 0

select amount_bid from vw_ppdai 
where id = 'http://invest.ppdai.com/loan/info?id=33710278'

-- 待投
select * from vw_ppdai
where amount_bid > 0 and bid  is null

--最近投过的
select * from vw_ppdai
where bid is not null
order by insert_dt desc


select * from vw_ppdai
where education_level = '本科'
and education_method = '普通' and wsl_rank < 150
and title not like '%闪电%'
order by insert_dt desc

update ppdai set bid = 1 where id = 'http://invest.ppdai.com/loan/info?id=15701925'

update ppdai set bid = 0 where id = 'http://invest.ppdai.com/loan/info?id=16325102'