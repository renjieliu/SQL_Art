-- plotting : "y = 10 * x + 5"

drop table if exists #dots

; with cte as 
(select n = 1, x = cast(1.0 as decimal(10,1) )
    union all 
select n+1 , cast(x + 0.1 as decimal(10,1) )  from cte
where n < 100
)
select *, y = NULL 
into #dots 
from cte 
OPTION(maxrecursion 0)


select * from #dots

--  TODO : next is to based on the formula to calculate the y





