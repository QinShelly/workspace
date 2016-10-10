
drop view vw_ppdai_original;
create view vw_ppdai_original as
SELECT p.id,  amount,
CASE WHEN age <= 39
       AND rate > 18
       AND amount + waiting_to_pay <= 15000
       AND title NOT LIKE '%闪电%'
       AND cnt_return_less_than_15 < 3
       AND education_level IN ('本科', ' 硕士研究生', '博士研究生', '硕士', '第二学士学位', '博士')
     THEN CASE WHEN education_method IN ('普通', '普通全日制', '研究生')
               THEN CASE
                   WHEN wsl_rank < 10 THEN 500 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN wsl_rank < 20 THEN 400 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN wsl_rank < 40 THEN 266 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN wsl_rank < 80 THEN 200 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN wsl_rank < 120 THEN 166 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN wsl_rank < 150 THEN 133 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN star >= 6 THEN 333 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN star >= 5 THEN 233 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN star >= 4 THEN 166 * 2 + CASE WHEN sex = '女' THEN 50 ELSE 0 END
                   WHEN wsl_rank < 200 THEN 0  + CASE WHEN sex = '女' THEN 0 ELSE 0 END
                   ELSE 0
                   END
                 + CASE WHEN (certificates_in_str LIKE '%央行征信报告%' OR certificates_in_str LIKE '%人行征信认证%')
                            AND rate > 18
                        THEN 51 * 2 ELSE 0 END
                 + CASE WHEN certificates_in_str LIKE '%个人常用银行流水%' AND rate > 18 THEN 50 * 2 ELSE 0 END
                 + CASE WHEN certificates_in_str LIKE '%公积金资料%' AND rate > 18 THEN 49 * 2 ELSE 0 END
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
       THEN 37 * 2 ELSE 0 END
+ CASE WHEN waiting_to_get_back - 1.2 * amount >= 0 AND rate > 18 THEN 66 * 2 ELSE 0 END
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