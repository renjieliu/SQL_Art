set nocount on ; 
 
drop table if exists #formula

select
y = 'sin(x)' 
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
declare @x decimal(38, 2) = -5.0
declare @x_end decimal(38, 2) = -@x
declare @x_step decimal(38, 2) = 0.01
declare @y decimal(38, 2)

while @x <= @x_end
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
set @x = @x + @x_step

end 


-- select * from #calc


---plot - to generate 256*256 points, if (y, x) in the table, then 1 else 0


drop table if exists #y_middle

select y_middle = y into #y_middle
from (
	select rn = ROW_NUMBER() over(order by id), cnt = count(*) over (), * from #calc 
) _ 
where rn in (cnt / 2)  -- (cnt / 2 + 1 , (cnt + 1) / 2  )  -- this is to get the median line, not calculating the median value


drop table if exists #dots_draft

select distinct 
b.x
, a.y
 , dot = case 
              when a.x = b.x and a.y = b.y then '#'  -- this is the one calculated
			  when b.x = 0 then nchar(65372)
			  when a.y = 0 then '>'
			  --when a.y = (select y_middle from #y_middle) then '>' -- nchar(9135)
              else ' ' -- filler 
         end 
into #dots_draft 
from #calc a, #calc b  -- for all the calculated y, get x, from -10 to 10
order by a.y, b.x 




-- to clean up cases like this -- the second line is from (48, 2304)
--    x                                       y                                    dot
----------------------------------------- --------------------------------------- ----
--  -48.00                                  2304.00                                 #
--  -48.00                                  2304.00                                 `



drop table if exists #dots 
; with cte as
(
	select rn = ROW_NUMBER() over (partition by x, y order by case when dot = '#' then 1 else 2 end), * from #dots_draft
)

select * into #dots
from cte 
where rn = 1 
option (maxrecursion 0)




select 
y
, line_item = cast(STRING_AGG(dot, '') within group (order by x) as varchar(max))
from #dots 
-- where y > 2000 
group by y
order by y desc  




-- select y, cast(STRING_AGG(dot, '') within group (order by x) as varchar(max)) from #dots where y = 2304 group by y  order by y desc  
--where dot  != ' '

--select *  from #dots where y = 2304  
--order by x


select * from #y_middle