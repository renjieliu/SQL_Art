/* 
1. define the image size, 128 
2. from -1 to 1, evenly distribute the 128 numbers
3. generate a panel, from (-1,-1) to (1,1), total points is 128*128 
4. for each point in the panel, assign the value, based on the calculation on step 2 
   4.1 from left to right, the number is -1 to 1 
   4.2 from up to down, the number is 1 to -1
   4.3 for each point, there should be 2 numbers, one is from X-axis, one is from Y-axis. These 2 numbers will be used for calculation later
5. for each point in the panel, go through the prospero instruction, get the result
6. generate the final output
*/

drop table if exists #tmp_space

; with cte as 
(select loc = cast(-1 as decimal(38,10)), iter = 1, starting = -1, ending = 1, total_cnt = 128.0
union all 
select loc = cast(-1 + (ending-starting) * ( iter / (total_cnt - 1))  as decimal(38,10))
, iter+1
, starting
, ending
, total_cnt  
 from cte 
where iter <= total_cnt-1
)
select * into #tmp_space
 from cte 
option (maxrecursion 0)

--for grid_x , it's just repeat the numbers for each row
drop table if exists #grid_x

; with cte_grid_x as 
(
    select col = iter, row = 1, val = loc, total_cnt from #tmp_space
    union all 
    select col, row + 1, val, total_cnt from cte_grid_x
    where row < total_cnt 
) 
select * into #grid_x from cte_grid_x 
option (maxrecursion 0)


-- for grid_y, it's a transpose of the space array, and repeat for 128 times

drop table if exists #grid_y

; with cte_grid_y as 
(
select 
row = col 
, col = row  -- row becomes column
, val 
, total_cnt 
from #grid_x
where col = 1 

union all 

select
curr.row+1
, col = x.row
, x.val
, x.total_cnt
from cte_grid_y curr 
inner join #grid_x x on x.col = curr.row + 1 and x.row = curr.col
)
select * into #grid_y from cte_grid_y 
option (maxrecursion 0 )


select 
 x = (select val from #grid_x where row = f_y and col = f_x)
, y = (select val from #grid_y where row = f_y  and col = f_y)
from (values (1, 128)) _ (f_x, f_y)



select * from #grid_x 

select * from #grid_y 
where [row] = 100



-- _0 const 2.95
-- _1 var-x
-- _2 const 8.13008
-- _3 mul _1 _2
-- _4 add _0 _3
-- _5 const 3.675
-- _6 add _5 _3
-- _7 neg _6
-- _8 max _4 _7
-- _9 const 0.175
-- _a neg _4
-- _b square _a
-- _c const 6.025
-- _d var-y
-- _e mul _d _2
-- _f add _c _e
-- _10 square _f
-- _11 add _b _10
-- _12 sqrt _11
-- _13 sub _9 _12
-- _14 max _8 _13
-- _15 const 0.275
-- _16 sub _12 _15
-- _17 max _14 _16

-- const case when 2.95 
-- const insert into 8.13 
-- mul = _1 _2
-- var-x = -1 

-- var-y = -1



select * from u_split_string('var-x', ' ')






