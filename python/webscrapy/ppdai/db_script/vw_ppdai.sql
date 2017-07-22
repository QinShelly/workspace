
drop view vw_ppdai;
create view vw_ppdai as
SELECT p.id,  amount,
CASE WHEN rate >= 20 AND age <= 39 
        and amount + waiting_to_pay <= 15000
        and cnt_return_less_than_15 < 3
        and over15plus = 0 then 
    CASE WHEN education_level IN ('本科', ' 硕士研究生', '博士研究生', '硕士', '第二学士学位', '博士')
       THEN CASE WHEN education_method IN ('普通', '普通全日制', '研究生')
                 THEN CASE
                     WHEN wsl_rank <= 10  THEN 200 + CASE WHEN sex = '女' THEN 40 ELSE 0 END
                     WHEN wsl_rank <= 20  THEN 150 + CASE WHEN sex = '女' THEN 30 ELSE 0 END
                     WHEN wsl_rank <= 40  THEN 100 + CASE WHEN sex = '女' THEN 20 ELSE 0 END
                     WHEN wsl_rank <= 80  THEN 75  + CASE WHEN sex = '女' THEN 15 ELSE 0 END
                     WHEN wsl_rank <= 120 THEN 75  + CASE WHEN sex = '女' THEN 15 ELSE 0 END
                     WHEN wsl_rank <= 150 THEN 50  + CASE WHEN sex = '女' THEN 10 ELSE 0 END
                     WHEN wsl_rank <= 200 THEN 0   + CASE WHEN sex = '女' THEN 0 ELSE 0 END
                     ELSE 0
                     END
                 WHEN education_method IN ('成人', '自考', '自学考试')
                 THEN CASE
                      WHEN wsl_rank <= 20 AND sex = '女' THEN 50 
                      ELSE 0
                      END
             END
       ELSE 0
  END
  + CASE WHEN ppdai_level in ('A','B','C') AND cnt_return_on_time >= 13 
        AND education_level <> '无'
        --AND title NOT LIKE '%闪电%'
          THEN 50 ELSE 0 END
  + CASE WHEN  (waiting_to_get_back - waiting_to_pay ) - 1.2 * amount >= 0 
          THEN 50 ELSE 0 END
end as amount_bid,
p.sex, p.insert_dt, p.school, p.education_level, p.education_method, s.wsl_rank,
p.rate, p.age, p.title, p.waiting_to_pay, p.cnt_return_less_than_15,
ppdai_level,  limitTime,  purpose, marriage, education, house, car, detail, hukou,
certificates_in_str, cnt_return_on_time, over15plus, total_borrow, waiting_to_get_back
FROM ppdai p
LEFT JOIN school_rank s
  ON p.school = s.school;



drop view vw_clean_ppdai;
create view vw_clean_ppdai as
select amount_bid bid,
rate rt,
amount amnt,
waiting_to_pay pay,
waiting_to_get_back b,
school,
education_level e_lv,
education_method e_m,
wsl_rank rk,
age,
ppdai_level lv,
cnt_return_on_time rot,
cnt_return_less_than_15 l15,
over15plus o15,
id,
title,
insert_dt
from vw_ppdai
