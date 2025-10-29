-- Below T-SQL is for running length encoding




; with src as 
(select word = replicate('teeth', 100))
, cte as  -- if it's same as previous character, then adding 1 to the counter else start at 1
( select rn = 1 , c = left(word, 1), ctr = 1,  rem = substring(word, 2, len(word)) from src
union all 
 select rn + 1 , c = left(rem, 1), iif(left(rem, 1) = c, ctr + 1 , 1), rem = substring(rem, 2, len(rem)) from cte
 where len(rem) > 0
) 
, rpt as -- using row_number - ctr to find islands
( select island = ROW_NUMBER() over(order by rn) - ctr, * from cte 
)
select  c, cnt = max(ctr) from rpt 
group by island, c  
order by island 
option (maxrecursion 0)




--- ############### previous approach ###############


; with base as 
(select word = 'tteeeeethh')
, cte as 
( select rn = 1 , c = left(word, 1), rem = substring(word, 2, len(word)) from base
union all 
 select rn + 1 , c = left(rem, 1), rem = substring(rem, 2, len(rem)) from cte
 where len(rem) > 0
 ), rpt as ( -- find the start and end character
select rn, c from cte c1 
where not exists ( select * from cte c2 where c2.rn-c1.rn  = 1 and c2.c = c1.c)
	   or 
	 not exists ( select * from cte c2 where c1.rn-c2.rn  = 1 and c2.c = c1.c)
) 
, cte2 as (
select
c
, rn
, start_ = case when lag(c, 1, '') over (order by rn) != c then rn else lag(rn, 1, rn) over(order by rn) end 
, end_ = case when lead(c, 1, '') over(order by rn ) = c then lead(rn, 1, rn) over(order by rn) else rn end
from rpt 
) 
select 
distinct
c
--, rn
, start_ 
, end_
, spread = end_ - start_ + 1
, dict 
from cte2 cross apply ( select dict = concat(c, end_ - start_ + 1) ) ap1
order by 2


; 




