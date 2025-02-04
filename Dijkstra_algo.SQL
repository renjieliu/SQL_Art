-- For each heap popped head, it should only returns on line, and from that one line, the recursive CTE goes on 
-- Need to have a wrapper function - dijk to compute the compare and return logic
-- dijk (hash, heap, node, connected_nodes) --> return table, which has hash, heap as columns




create or alter function initialize_hashmap(@nodeString varchar(max), @val bigint)
-- param: nodes (A,B,C,D,E), val
-- return hashmap |A.val|B.val... 

returns table as return 

with base as 
(select nodes = @nodeString ) -- union all select 'B' union all select 'C' )
select hashmap = '|' + STRING_AGG( concat_ws('.', node, @val), '|') 
from base 
    cross apply (select node = [value] from string_split(nodes, ',' ) ) cra
 

go 




create or alter function heappop(@heap varchar(max))
-- A.100|B.10|C.12 --> B.10
-- parameter: heapString
-- return string: lowest nodeX.cost
returns table as return 
with base as 
(
    select input = @heap
)
, to_pop as (
    select  
    rn = ROW_NUMBER() over (order by cast(PARSENAME(cra.grp,1) as int))
    , score = PARSENAME(cra.grp,1)
    , node = PARSENAME(cra.grp, 2)
    from base
    cross apply (select grp = [value] from string_split([input], '|')) cra
    where isnull(grp, '')!= ''
) 
select 
heap_top = (select heap_top = node + '.' + score 
                from to_pop 
                where rn = 1
            )
, heap_rem = isnull((select string_agg(node + '.' + score, '|') within group(order by score) 
                from to_pop where rn != 1 
                    )
                , '')
go 

-- select * from heappop('|A.100')


go

create or alter function heappush(@heap varchar(max), @nodes_costs varchar(max))
--- heappush -- 500.D  --> @heap + @newNodeCost
-- parameter: heapString, new nodeX.Cost
-- return: heapString after concatenation
returns table as return 
with cte_heap as (
    select 
    node = PARSENAME([value], 2)
    , val = PARSENAME([value], 1)
    from string_split(@heap, '|') _
    where [value] != ''
)
, cte_updates as 
(
    select 
    node = PARSENAME([value], 2)
    , val = PARSENAME([value], 1)
    from string_split(@nodes_costs, '|') _
    where [value] != ''
)
, updated as 
(
    select 
    node 
    , val
    from cte_heap 
    where node not in (select node from cte_updates) -- the nodes irrelevant to current updates
    union 
    select 
    node
    , val
    from cte_updates u
    where node not in (select node from cte_heap) -- new nodes
        or 
        exists (select * from cte_heap h where h.node = u.node and u.val < h.val) -- val < heap val
)
select 
heap = '|' + string_agg(CONCAT_WS('.', node, val), '|') within group (order by node)
from updated
go

-- select * from heappop('|B.2|C.6')

-- node.cost


-- Costs - this is a hashmap, to store the lowest cost for current node 

-- the heap is used to get the lowest cost for all the nodes, and iterate for all the nodes connecting to it


-- for each node, initiate like 'node1.cost|node2.cost'

-- get from costs, check if current node cost is < nodex.cost


-- getFromSet 
-- parameter: setString, nodeX
-- return nodeX.cost

go 


create or alter function getNodeVal(@hashmap varchar(max), @node varchar(max))
-- |A.0|B.99999|C.99999|, B  --> 99999
-- parameter: nodeX (|node.) , hashmap
-- return: cost
returns table as return 
with cte as 
(select rem = right(@hashmap, len(@hashmap) - CHARINDEX(@node, @hashmap)))
select cost = SUBSTRING(@hashmap
                , CHARINDEX(@node+'.', @hashmap) + datalength(@node) + 1  -- from this location
                , CHARINDEX('|', rem) - datalength(@node) - 1
                )   
from cte


go



create or alter function updateCost (@hashmap varchar(max), @nodes_costs varchar(max))
-- updateCost(|A.0|B.99999|C.199, '|A.200|B.300') --> |A.200|B.300|C.199
-- parameater: hashmap,  nodes_costs
-- return hashmap string after update
returns table as return
with cte_hashmap as (
    select 
    node = PARSENAME([value], 2)  
    , val = cast(PARSENAME([value], 1) as bigint)
    from string_split(@hashmap, '|') _
    where [value] != ''
)
, cte_updates as 
(
    select 
    node = PARSENAME([value], 2)
    , val = cast(PARSENAME([value], 1) as bigint)
    from string_split(@nodes_costs, '|') _
    where [value] != ''
)
, updated as 
(
    select 
    node = prev.node
    , val = case when curr.node is not null and curr.val < prev.val then curr.val
                 else prev.val
            end
    from cte_hashmap prev left outer join cte_updates curr
    on prev.node = curr.node
)
select 
hashmap = '|' + string_agg(CONCAT_WS('.', node, val), '|') within group (order by node)
from updated
go 


select * from updateCost('|A.0|B.2|C.6|D.7|E.99999|F.99999|G.99999|H.99999', 'D.14') _ 


create or alter function dijk(@nodes_costs varchar(max) -- node.cost|node.cost
                             , @hashmap varchar(max)
                             , @heap varchar(max)
                              )
returns table as return
--- this function is a wrappe for the steps of dijkstra's algo

-- step 1 -- update the hashmap with the new cost 
-- step 2 -- push the lower cost into the heap 
-- step 3 -- return hashmap, and heap as the result 

-- node_costs |A.100|B.200|C.300
-- hashmap:  |A.0|B.99999|C.99999|D.99999|E.99999|F.99999|G.99999|H.99999
-- heap: |A.0 
select hashmap, heap from updateCost(
                        @hashmap
                        , @nodes_costs) _update_hashmap -- update the hashmap 
                    cross apply 
                        heappush(
                        @heap
                        ,@nodes_costs
                    ) _heap_push


go





-------------------------------------------------------

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

go


; with cte as 
(
select 
step = 0
, Node = cast('A' as varchar(max))
, hashmap  = cast ((select _start_node.hashmap
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
                cross apply (select hashmap from initialize_hashmap(nodes, 99999)) _ini
                cross apply (select hashmap from updateCost(hashmap, '|A.0')) _start_node
                 )
             as varchar(max)) 
, heap = cast( (select heap from heappush('','|A.0') _ ) as varchar(max))
, heap_node = cast('-' as varchar(max))
, heap_rem = cast('-' as varchar(max))
, nodes_costs = cast('' as varchar(max))
union all 

select 
step + 1
, cast(_heap_top.heap_node  as varchar(max))-- this need to be the popped node
, cast( _dijk.hashmap as varchar(max)) -- =   cast( _update_hashmap.hashmap as varchar(max))
, cast( _dijk.heap as varchar(max))-- = cast( _push_new_value_to_heap.heap as varchar(max)) 
, cast(_heap_top.heap_node as varchar(max))
, cast(_heap_top.heap_rem as varchar(max))
, nodes_costs = cast(_nodes_costs.nodes_costs as varchar(max))
from cte c
cross apply (select -- pop the heap 
            heap_node = parsename(heap_top, 2)
            , heap_cost = cast(parsename (heap_top, 1) as bigint)
            , heap_rem 
            from heappop(c.heap) 
            ) _heap_top  -- cross apply alias cannot be referenced in another cross apply 

cross apply (
            select nodes_costs_xml = (
                                    select 
                                    -- connected_node = nodes.node2 
                                    -- , connected_node_cost = heap_cost + nodes.cost
                                    --, 
                                    combined = concat(nodes.node2,  '.', cast( (heap_cost + nodes.cost) as varchar(max)), '|')
                                    from #input nodes 
                                    where nodes.Node1 = _heap_top.heap_node 
                                    for xml path('')
                                )  
            ) _nodes_costs_xml
  -- find all the nodes connect to the heap top

cross apply 
(select nodes_costs_cleaned = replace( 
                                replace(nodes_costs_xml
                                        , '<combined>'
                                        , ''
                                    ) 
                                , '</combined>' 
                            , '')
) _nodes_costs_xml_cleaned
cross apply 
(
select nodes_costs = left(nodes_costs_cleaned, len(nodes_costs_cleaned)- 1) 
) _nodes_costs
cross apply (
            select 
            hashmap
            , heap
            from dijk(
                    _nodes_costs.nodes_costs
                    , c.hashmap
                    , _heap_top.heap_rem --c.heap
                    ) _
            ) _dijk


where c.heap != '' -- until the heap is all popped
-- and step < 5 
) 

select * from cte 
option (maxrecursion 0)



-- select 
-- hashmap
-- , heap
-- from dijk(
--     'B.2|C.6'
--     , '|A.0|B.2|C.6|D.99999|E.99999|F.99999|G.99999|H.99999'
--     , '' --c.heap
--     ) _
 

-- cross apply (
--     select prev_cost = cast(cost as bigint) from getNodeVal(hashmap, _nxt_nodes.connected_node ) -- get the cost of the connected node
-- ) _costs -- get the cost of the node

-- cross apply (
--     select new_cost = case when prev_cost <= heap_cost + connected_node_cost then prev_cost 
--                            else heap_cost + connected_node_cost 
--                        end 
-- ) _new_cost -- to get the new cost for the connected nodes

-- cross apply (
--     select hashmap from updateCost(hashmap, connected_node,  new_cost)
--     where new_cost < prev_cost
-- ) _update_hashmap -- update the hashmap 

-- cross apply (
--     select heap from heappush( heap, concat_ws('.', connected_node, new_cost) ) _heap_push
--     where new_cost < prev_cost
-- ) _push_new_value_to_heap



-- getNodeVal(@hashmap varchar(max), @node varchar(max))

-- heappush(@heap varchar(max), @newNodeCost varchar(max))
-- updateCost
-- getNodeVal
-- initialize_hashmap
-- heappop

 -- nodeX.Cost











-- select * from getNodeVal('|A.0|B.99999|C.99999|D.99999|E.99999|F.99999|G.99999|H.99999', 'B' )


-- declare @hashmap varchar (max) = '|A.0|B.99999|C.99999|D.99999|E.99999|F.99999|G.99999|H.99999'
-- declare @node varchar(max)  = 'B'


-- ; with cte as 
-- (select rem = right('|A.0|B.99999|C.99999|D.99999|E.99999|F.99999|G.99999|H.99999', len(@hashmap) - CHARINDEX(@node, @hashmap)))
-- select cost = SUBSTRING(@hashmap
--                 , CHARINDEX(@node+'.', @hashmap) + datalength(@node) + 1  -- from this location
--                 , CHARINDEX('|', rem) - datalength(@node) - 1
--                 )   
-- from cte




-- create or alter function updateCost (@hashmap varchar(max), @node varchar(max), @cost bigint)
-- -- updateCost(|A.0|B.99999, 'A', 200) --> |A.200|B.99999
-- -- parameater: hashmap, NodeX, cost
-- -- return hashmap string after update
-- -- Eg. update B to 65121
-- returns table as return
-- with cte as (
-- select 
-- node = PARSENAME([value], 2)
-- , val = PARSENAME([value], 1)
-- from string_split(@hashmap, '|') _
-- where [value] != ''
-- ), updates as (
-- select 
-- node
-- , val
-- from cte 
-- where node != @node
-- union 
-- select 
-- @node
-- , @cost
-- ) 
-- select 
-- hashmap = '|' + string_agg(CONCAT_WS('.', node, val), '|') within group (order by node)
-- from updates

-- go 




-- create or alter function heappush(@heap varchar(max), @newNodeCost varchar(max))
-- --- heappush -- 500.D  --> @heap + @newNodeCost
-- -- parameter: heapString, new nodeX.Cost
-- -- return: heapString after concatenation
-- returns table as return 
-- select heap = CONCAT_WS('|', @heap, @newNodeCost) --  from base







-- ; with base as 
-- (select id = 'a' union all select id = 'b') 
-- , cte as 
-- (select * from base
-- union all 
-- select STRING_AGG(id, ',') within group( order by id ) from cte 
-- where id = 'b')
-- select * from cte


-- ; with base as 
-- (select id = 'a' union all select id = 'b') 
-- , cte as 
-- (select * from base
-- union all  
-- select  t = replace(
--                 replace( (select * from base for XML PATH(''))
--                         , '<id>'
--                         , ''
--                     )
--                 ,'</id>'
--                 , '|')
          
-- )
-- select * from cte 


-- cross apply (select nodes_costs = '|' + STRING_AGG(connected_node + '.' + connected_node_cost, '|')
--                                     within group (order by connected_node) 
--             )_string_agg