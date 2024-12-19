-- plotting : ""
set nocount on ; 


drop table if exists #formula

select
y = '10 * x + 5' 
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

drop table if exists #y 

select
id = 1
, x = cast(NULL as decimal(38, 2) )
, y = cast(NULL as decimal(38, 2) ) 
into #y 

truncate table #y

-- select * from #y

declare @i int = 1
declare @exec_sql nvarchar(max)
declare @x decimal(38, 2) = -10.0
declare @y decimal(38, 2)

while @x < 10.0 
begin
 select 
    @exec_sql = 'select ' + CONCAT_WS(', '
                                        , cast(@i as varchar) 
                                        , cast(@x as varchar)
                                        , replace(y, 'x', cast(@x as varchar)) 
                                    )
from #formula 

-- print @exec_sql

insert into #y 
exec sp_executesql @exec_sql
 
set @i = @i + 1
set @x = @x + 0.1

end 




select * from #y


---plot - to generate 256*256 points, if (y, x) in the table, then 1 else 0
