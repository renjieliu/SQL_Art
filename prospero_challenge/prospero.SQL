/* 
1. define the image size, 128 
2. from -1 to 1, evenly distribute the 128 numbers
3. generate a panel, from (-1,-1) to (1,1), total points is 128*128 
4. for each point in the panel, assign the value, based on the calculation on step 2 
   4.1 from left to right, the number is -1 to 1 
   4.2 from up to down, the number is 1 to -1
   4.3 for each point, there should be 2 numbers, one is from X-axis, one is from Y-axis. These 2 numbers will be used for calculation later
5. for each point in the panel, go through the prospero instruction, get the result
    -- go through the instruction, put the result of each step into a column
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



drop table if exists #grid 

select x.[row], x.col, x = x.val, y = y.val 
into #grid
from #grid_x x inner join #grid_y y 
on x.[row] = y.[row] and x.col = y.col


-- select 
--  x = (select val from #grid_x where row = f_y and col = f_x)
-- , y = (select val from #grid_y where row = f_y  and col = f_y)
-- from (values (1, 128)) _ (f_x, f_y)



-- select * from #grid_x 

-- select * from #grid_y 
-- where [row] = 100





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


-- SELECT cast(CONVERT(varbinary, '0F', 2) as int) -- OK
-- SELECT cast(CONVERT(varbinary, '0x0F', 1) as int) -- OK
-- SELECT cast(CONVERT(varbinary, '0F', 2) as int) -- OK
-- SELECT cast(CONVERT(varbinary, 'F', 2) as int) -- failed , as 'F' is odd-length, varbinary requires even-numbered digits
-- SELECT cast(CONVERT(varbinary, '0xF', 1) as int) -- failed , as 'F' is odd-length, varbinary requires even-numbered digits



drop table if exists #prospero

select 
step_id  = cast(CONVERT(varbinary, step_padded ,2) as int )
, step
, op = [action] 
, op1 = case when op1 = 'NULL' then '' else op1 end
, op2 = case when op2 = 'NULL' then '' else op2 end
, res
into #prospero
from prospero_instruction
cross apply (select step_cleaned =  upper(REPLACE(step, '_', '') ) ) _
cross apply (select step_padded = case when len(step_cleaned) % 2 = 0 then step_cleaned else '0' + step_cleaned end) __



-- select 
-- * 
-- from #prospero p1
-- order by 1


-- commit 
-- select * from prospero_instruction order by convert(int, (CONVERT(varbinary, REPLACE(step, '_', ''), 1) ) )


-- select * from #prospero
-- alter table prospero_instruction add res varchar(100)

-- select * from #grid_x
-- select * from #grid_y 


-- select * from #step_lookup 


go 


create or alter function prospero_get_step_res(@concated varchar(max), @step varchar(100))
returns table 
as 
return 

select res = res.val from 
    (select op_by_step = value from string_split(@concated, '`') ) ap1  
    outer apply  
    (select val from u_split_string(ap1.op_by_step, '|') where id = 5) res
where op_by_step like @step+ '|%'

go 



------------ Testing code for prospero_get_step_res ------------
; with cte as 
(
select 
n = STRING_AGG( cast( CONCAT_WS('|', cast(step_id as varchar) , op, op1, op2, isnull(res, 'NULL')) as varchar(max)), '`') 
within group(order by step_id) 
, x= 1
, y = 1 
from #prospero, #grid 
where col = 1 and row = 1  -- x = 1, y = 1
) 
select ap1.* from cte cross apply 
    (select * from prospero_get_step_res(n, 1)) ap1



go 

 

create or alter function prospero_update_step_res(@concat varchar(max), @step varchar(100), @res_val varchar(100))
returns table 
as 
return 
with cte as (
select 
op_by_step 
, step_res = string_agg(res.val , '|') within group (order by id)
from 
    (select op_by_step = value from string_split(@concat, '`')) ap1  -- split the string into steps
    cross apply  
    (
	 select id, val from u_split_string( ap1.op_by_step, '|') where id != 5 -- for the target step, split into op, op1, op2... 
		union
	 select 5, @res_val	-- put the value to the spot, the result value is on 5th column
	) res
where op_by_step like @step+ '|%'
group by op_by_step
)
select 
updated_res = stuff(@concat -- the original string
				  , charindex('`' + @step+ '|' , @concat)+1 -- starting from this node position
				  , len(op_by_step)  -- the node string length
				  , step_res  --concated the updated node string 
				  )
from cte

go 


------------ Testing code for prospero_update_step_res ------------
; with cte as 
(
select 
n = STRING_AGG( cast( CONCAT_WS('|', cast(step_id as varchar) , op, op1, op2, isnull(res, 'NULL')) as varchar(max)), '`') 
within group(order by step_id) 
, x= 1
, y = 1 
from #prospero, #grid 
where col = 1 and row = 1  -- x = 1, y = 1
) 
select ap1.* from cte cross apply 
    (select * from prospero_update_node_res(n, 2, 1000)) ap1



go 






create or alter function prospero_compute_step(@concat varchar(max), @step varchar(100), @x varchar(100), @y varchar(100))
returns table 
as return 
select
step_id = step_id.val
, op = op.val
, op1_base = op1_base.val 
, op2_base = op2_base.val
, op1_ref = op1_ref.op1
, op2_ref = op2_ref.op2
, op1 = op1_final.op1 
, op2 = op2_final.op2 
, res =  case when op.val ='const' then op1_final.op1
              when op.val = 'add' then op1_final.op1 + op2_final.op2 
              when op.val = 'max' then iif(op1_final.op1 >= op2_final.op2, op1_final.op1, op2_final.op2)
              when op.val = 'min' then iif(op1_final.op1 <= op2_final.op2, op1_final.op1, op2_final.op2) 
              when op.val = 'mul' then op1_final.op1 * op2_final.op2
              when op.val = 'neg' then -op1_final.op1
              when op.val = 'sqrt' then power(op1_final.op1, 0.5)
              when op.val = 'square' then power(op1_final.op1,  2)
              when op.val = 'sub' then op1_final.op1 - op2_final.op2
              when op.val = 'var-x' then cast(@x as decimal(38, 10))
              when op.val = 'var-y' then cast(@y as decimal(38, 10))
              else -999999999
            end

from 
    (select step_op = value from string_split(@concat, '`') ) ap1  
    cross apply  
    (select val from u_split_string(ap1.step_op, '|') where id = 1) step_id
    cross apply  
    (select val from u_split_string(ap1.step_op, '|') where id = 2) op
    outer apply  -- using outapply in case op1 does not exist
    (select val from u_split_string(ap1.step_op, '|') where id = 3) op1_base
	outer apply
	(select op1 = case when isnull(op1_base.val, '') not like '`_%' escape '`' then op1_base.val -- if it's not a reference
					   else (
							 select res from prospero_get_step_res(@concat
																	, 
																  (cast( convert( varbinary, iif( len(op1_base.val) % 2 = 1, '', '0') + replace(op1_base.val, '_', ''), 2) as int)) 
																  )-- if it's a reference, get the res from the @concat
						    )
					   end 			
     ) op1_ref
	outer apply
	(select op1 = cast(op1_ref.op1 as decimal(38, 10))) op1_final
    outer apply  
    (select val from u_split_string(ap1.step_op, '|') where id = 4) op2_base 
	outer apply  -- using outapply in case op2 does not exist
	(select op2 = case when isnull(op2_base.val, '') not like '`_%' escape '`' then op2_base.val -- if it's not a reference
					   else (
							 select res from prospero_get_step_res(@concat
																	, 
																  (cast( convert( varbinary, iif( len(op2_base.val) % 2 = 1, '', '0') + replace(op2_base.val, '_', ''), 2) as int)) 
																  )-- if it's a reference, get the res from the @concat
						    )
					   end 			
     ) op2_ref
	outer apply 
	(select op2 =cast(op2_ref.op2 as decimal(38, 10))) op2_final

where ap1.step_op like @step  + '|%' 




go 


------------ Testing code for prospero_compute_step ------------

; with cte as 
(
select 
n = STRING_AGG( cast( CONCAT_WS('|', cast(step_id as varchar) , op, op1, op2, isnull(res, '')) as varchar(max)), '`') 
within group(order by step_id) 
, x= 1
, y = 1 
from #prospero, #grid 
where col = 1 and row = 1  -- x = 1, y = 1
) 
select * from cte cross apply 
	-- (select step_op = value from string_split(n, '`') ) ap0  outer apply 
    (select * from prospero_compute_step(n, 1, x, y)) ap1

-- commit 

-- select * from #step_lookup 

select * from #prospero
where step_id between 4403 and 4406

--select op , * from #prospero 
--where op = 'sqrt'
--order by 1 

--select distinct op from #prospero 
--order by 1 



select * from #prospero 
order by 1 



-- prospero_compute_step 
-- prospero_get_step_res
-- prospero_update_step_res


go


create or alter function prospero_wrap(@concat varchar(max), @total_iter int,   @x varchar(max),  @y varchar(max))
returns table 
as 
return 

with cte as 
(
select 
curr_step = 1
, res = @concat 

union all 

select curr_step + 1 
, updated.updated_res
from cte
	cross apply (select comp_res = res from prospero_compute_step(res, curr_step, @x, @y) ) comp
	cross apply (select updated_res  from prospero_update_step_res(res, curr_step, comp_res) ) updated
where curr_step < @total_iter
) 
select 
* 
from cte
where curr_step = @total_iter 



go 



; with cte as 
(
	select 
	n = STRING_AGG( cast( CONCAT_WS('|', cast(step_id as varchar) , op, op1, op2, isnull(res, '')) as varchar(max)), '`') within group(order by step_id) 
	, x = 1
	, y = 1
	from #prospero, #grid 
	where col = 1 and row = 1  -- and step_id between 4403 and 4406-- x = 1, y = 1
) 
select 
step_op, op1_base.*, op0, turn,  op_final
from cte cross apply 

   (select step_op = value from string_split(n, '`') ) ap1  
    cross apply  
    (select val from u_split_string(ap1.step_op, '|') where id = 1) step_id
    cross apply  
    (select val from u_split_string(ap1.step_op, '|') where id = 2) op
    outer apply  -- using outapply in case op1 does not exist
    (select val from u_split_string(ap1.step_op, '|') where id = 3) op1_base
	outer apply
	(select 
						   
		op0 =   cast( case when isnull(op1_base.val, '') not like '`_%' escape '`' then op1_base.val -- if it's not a reference
					   else 					   
					    iif( len(op1_base.val) % 2 = 1, '', '0') + replace(op1_base.val, '_', '')
			   
				end as varchar(max))
			, turn = case when isnull(op1_base.val, '') like '`_%' escape '`' then 1 else 0  end 
	) op_t
	outer apply
	(select 
	 op_final = case when turn = 1 then try_cast( try_cast(TRY_CONVERT(varbinary, op0, 2) as int) as decimal(38, 10))
				else cast(op0 as decimal(38, 10)) end 
	 ) op_ref 
	 

   --  (select * from prospero_wrap(n, (select count(*) from #prospero), x, y)) res
option (maxrecursion 0)


--prospero_update_step_res(@concat varchar(max), @step varchar(100), @res_val varchar(100))


--goprospero_compute_step
 