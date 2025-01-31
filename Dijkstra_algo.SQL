create or alter function heappop(@heapString varchar(max))
-- stk: score.node|
-- 120.A|200.B|300.C
-- pop -- > and push back 
-- adding 400.D to the stack 


---- heappop 
-- parameter: heapString
-- return string: lowest nodeX.cost
returns table as return 
with base as 
(
    select input = @heapString
)
, to_pop as (
select top 1 
score = PARSENAME(cra.grp,2)
, node = PARSENAME(cra.grp, 1)
 from base
    cross apply (select grp = [value] from string_split([input], '|')) cra
order by score, node 
) 
select top_stk =  score + '.' + node from to_pop 

go 



create or alter function heappush (@heapString varchar(max), @newNodeCost varchar(max))
--- heappush -- 500.D 
-- parameter: heapString, new nodeX.Cost
-- return: heapString after concatenation
returns table as return 
with base as 
(
    select input =@heapString 
)
select res = CONCAT_WS('|', input, @newNodeCost) from base

go


-- Costs - this is a hashmap, to store the lowest cost for current node 

-- the heap is used to get the lowest cost for all the nodes, and iterate for all the nodes connecting to it


-- for each node, initiate like 'node1.cost|node2.cost'

-- get from costs, check if current node cost is < nodex.cost


-- getFromSet 
-- parameter: setString, nodeX
-- return nodeX.cost

go 


create or alter  FUNCTION initialize_hashmap(@nodeString varchar(max), @val bigint)
-- 'A,B,C,D,E'
-- initialize the hashmap
-- param: nodes (A,B,C,D,E), val
-- return hashmap |A.val|B.val... 

returns table as return 

with base as 
(select nodes = @nodeString ) -- union all select 'B' union all select 'C' )
select hashmap = '|' + STRING_AGG( concat_ws('.', node, @val), '|') 
from base 
    cross apply (select node = [value] from string_split(nodes, ',' ) ) cra
 

go 



go 

create or alter function getNodeVal(@hashmap varchar(max), @node varchar(max))
-- Get cost from the string
-- get the cost of B
-- parameter: nodeX (|node.) , hashmap
-- return: cost
returns table as return 
with cte as 
(select rem = right(@hashmap, len(@hashmap) - CHARINDEX(@node, @hashmap)))
select cost = SUBSTRING(@hashmap
                , CHARINDEX('@node.', @hashmap) + datalength(@node)  -- from this location
                , CHARINDEX('|', rem) - datalength(@node)
                )   
from cte


go


 

create or alter function updateCost (@hashmap varchar(max), @node varchar(max), @cost bigint)
-- update the cost for NodeX in the hashmap string 
-- parameater: hashmap, NodeX, cost
-- return hashmap string after update
-- Eg. update B to 65121
returns table as return
with cte as (
select 
node = PARSENAME([value], 2)
, val = PARSENAME([value], 1)
from string_split(@hashmap, '|') _
where [value] != ''
), updates as (
select 
node
, val
from cte 
where node != @node
union 
select 
@node
, @cost
) 
select 
hashmap = '|' + string_agg(CONCAT_WS('.', node, val), '|') within group (order by node)
from updates

go 


drop table if exists #input

SELECT 'A' AS Node1, 'B' AS Node2, 2 AS Cost
into #input
UNION
SELECT 'A' AS Node1, 'C' AS Node2, 6 AS Cost
UNION
SELECT 'B' AS Node1, 'D' AS Node2, 5 AS Cost
UNION
SELECT 'C' AS Node1, 'D' AS Node2, 8 AS Cost
UNION
SELECT 'C' AS Node1, 'E' AS Node2, 2 AS Cost
UNION
SELECT 'D' AS Node1, 'F' AS Node2, 10 AS Cost
UNION
SELECT 'D' AS Node1, 'G' AS Node2, 15 AS Cost
UNION
SELECT 'G' AS Node1, 'F' AS Node2, 6 AS Cost
UNION
SELECT 'G' AS Node1, 'H' AS Node2, 6 AS Cost
UNION
SELECT 'F' AS Node1, 'H' AS Node2, 2 AS Cost
UNION
SELECT 'E' AS Node1, 'F' AS Node2, 20 AS Cost


select 
id = 1 
, currNode = 'A'
, hashmap  = (select start_node.hashmap
                from
                (
                    select nodes = STRING_AGG(node, ',') within group(order by node) from 
                    (
                        select node =  Node1 from #input
                        union  
                        select node2 
                        from #input
                    )  _ 
                ) n 
                cross apply (select hashmap from initialize_hashmap(nodes, 99999)) ini
                cross apply (select hashmap from updateCost(hashmap, 'A', 0)) start_node
            )






-- updateCost
-- getNodeVal
-- initialize_hashmap
-- heappush
-- heappop

