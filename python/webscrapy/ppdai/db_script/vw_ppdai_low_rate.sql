
drop view vw_ppdai_low_rate;
create view vw_ppdai_low_rate as
SELECT p.id,  amount,
CASE WHEN age <= 39
       AND rate > 15
       AND amount + waiting_to_pay <= 15000
       AND title NOT LIKE '%闪电%'
       AND cnt_return_less_than_15 < 3
       AND education_level IN ('本科', ' 硕士研究生', '博士研究生', '硕士', '第二学士学位', '博士')
     THEN CASE WHEN education_method IN ('普通', '普通全日制', '研究生')
               THEN CASE
                   WHEN wsl_rank < 10  THEN 200 + CASE WHEN sex = '女' THEN 40 ELSE 0 END
                   WHEN wsl_rank < 20  THEN 150 + CASE WHEN sex = '女' THEN 30 ELSE 0 END
                   WHEN wsl_rank < 40  THEN 100 + CASE WHEN sex = '女' THEN 20 ELSE 0 END
                   WHEN wsl_rank < 80  THEN 75  + CASE WHEN sex = '女' THEN 15 ELSE 0 END
                   WHEN wsl_rank < 120 THEN 75  + CASE WHEN sex = '女' THEN 15 ELSE 0 END
                   WHEN wsl_rank < 150 THEN 50  + CASE WHEN sex = '女' THEN 10 ELSE 0 END
                   WHEN star >= 6 THEN 50 + CASE WHEN sex = '女' THEN 0 ELSE 0 END
                   WHEN star >= 5 THEN 50 + CASE WHEN sex = '女' THEN 0 ELSE 0 END
                   WHEN star >= 4 THEN 50 + CASE WHEN sex = '女' THEN 0 ELSE 0 END
                   WHEN wsl_rank < 200 THEN 0  + CASE WHEN sex = '女' THEN 0 ELSE 0 END
                   ELSE 0
                   END
                 + CASE WHEN (certificates_in_str LIKE '%央行征信报告%' OR certificates_in_str LIKE '%人行征信认证%')
                            AND rate > 18
                        THEN 0 * 2 ELSE 0 END
                 + CASE WHEN certificates_in_str LIKE '%个人常用银行流水%' AND rate > 18 THEN 0 * 2 ELSE 0 END
                 + CASE WHEN certificates_in_str LIKE '%公积金资料%' AND rate > 18 THEN 0 * 2 ELSE 0 END
               WHEN education_method IN ('成人', '自考', '自学考试')
               THEN CASE
                   	WHEN wsl_rank < 150 THEN 0 + CASE WHEN sex = '女' THEN 0 ELSE 0 END
                   	ELSE 0
                   	END
           END
     ELSE 0
END
+ CASE WHEN ppdai_level = 'C' AND rate = 22 AND age < 40 AND cnt_return_on_time > 10 AND cnt_return_less_than_15 < 3
       AND title NOT LIKE '%闪电%' AND education_level IS NOT NULL
       THEN 0 * 2 ELSE 0 END
+ CASE WHEN waiting_to_get_back - 1.2 * amount >= 0 AND rate > 18 THEN 25 * 2 ELSE 0 END
       as amount_bid,
       p.sex,
       p.insert_dt,
       p.school,
       p.education_level,
       p.education_method,
       s.wsl_rank,
       p.rate,
       p.age,
       p.title,
       p.waiting_to_pay,
       p.cnt_return_less_than_15,
ppdai_level,  limitTime,  purpose, marriage, education, house, car, detail, hukou,
certificates_in_str, cnt_return_on_time, over15plus, total_borrow, waiting_to_get_back,
p.bid
FROM   ppdai p
       LEFT JOIN school_rank s
              ON p.school = s.school
       LEFT JOIN another
              ON p.id = another.id