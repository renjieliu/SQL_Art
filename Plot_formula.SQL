-- plotting : "https://www.wolframalpha.com/input?i=plot+x%5E3+-+6x%5E2+%2B+4x+%2B+12"

set nocount on ; 


drop table if exists #formula

select
y = 'x*x*x - 6*(x*x) + 4*x + 12' 
into #formula

-- drop table if exists #dots

-- ; with cte as 
-- (select n = 1, x = cast(1.0 as decimal(38,2) )
--     union all 
-- select n+1 , cast(x + 0.1 as decimal(38,2) )  from cte
-- where n < 500
-- )
-- select 
-- *
-- , y_formula = cast(NULL as varchar(max))
-- into #dots 
-- from cte 
-- OPTION(maxrecursion 0)

-- update #dots 
-- set y_formula = (select  replace(y, 'x', cast(x as varchar)) from #formula )

-- select *  from #dots

drop table if exists #calc 

select
id = 1
, x = cast(NULL as decimal(38, 2) )
, y = cast(NULL as decimal(38, 2) ) 
into #calc 

truncate table #calc

-- select * from #calc

declare @i int = 1
declare @exec_sql nvarchar(max)
declare @x decimal(38, 2) = -10.0
declare @y decimal(38, 2)

while @x <= 10.0 
begin
 select 
    @exec_sql = 'select ' + CONCAT_WS(', '
                                        , cast(@i as varchar) 
                                        , cast(@x as varchar)
                                        , replace(y, 'x', cast(@x as varchar)) 
                                    )
from #formula 

-- print @exec_sql

insert into #calc 
exec sp_executesql @exec_sql

 
set @i = @i + 1
set @x = @x + 0.1

end 




-- select * from #calc


---plot - to generate 256*256 points, if (y, x) in the table, then 1 else 0

drop table if exists #dots 

drop table if exists #y_middle

select y_middle = y into #y_middle
from (
	select rn = ROW_NUMBER() over(order by id), cnt = count(*) over (), * from #calc 
) _ 
where rn in (cnt / 2)  -- (cnt / 2 + 1 , (cnt + 1) / 2  )  -- this is to get the median line, not calculating the median value


select 
b.x
, a.y
 , dot = case 
              --when b.x = 0 then '^' -- nchar(65372)
			  --when a.y = (select y_middle from #y_middle) then '>' -- nchar(9135)
			  when a.x = b.x  then '#'  -- this is the one calculated
              else '.' -- filler 
         end 
into #dots 
from #calc a, #calc b  -- for all the calculated y, get x, from -10 to 10
order by a.y, b.x 


select 
y
, line_item = STRING_AGG(dot, '') within group (order by x)
from #dots 
group by y
order by y desc  



--select * from #dots
--where dot  != ' '