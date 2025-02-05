-- Dijkstra's algorithm steps
-- Set all the nodes cost with a large number, hashmap
-- Initialize the starting node's cost as 0, heap
-- While the heap is not empty, pop the heap top 
-- Get all the nodes connected to the heap top
-- Check if the heaptop cost + cost_to_the_node is smaller than previously computed, which was stored in the hashmap
-- If lower, update it in the hashmap, and push to the heap
-- When the heap is empty, get the smallest cost of the ending node.

-- To implemented the process in SQL, 
-- Below functions are created to make it more streamlined


-- f_initialize_hashmap(@nodeString varchar(max), @val bigint)
    -- param: nodes (A,B,C,D,E), val
    -- return hashmap |A.val|B.val... 

-- f_heappop(@heap varchar(max))
    -- A.100|B.10|C.12 --> B.10
    -- parameter: heapString
    -- return string: heap_top, heap_rem

-- f_heappush(@heap varchar(max), @newNodeCost varchar(max))
    -- parameter: heapString, |nodeX.Cost|nodeY.Cost
    -- return: heapString after concatenation

-- f_updateCost(@hashmap varchar(max), @nodes_costs varchar(max))
    -- (|A.0|B.99999|C.199, '|A.200|B.300') --> |A.200|B.300|C.199
    -- parameater: hashmap,  nodes_costs
    -- return hashmap string after update

-- f_dijk(@nodes_costs varchar(max), @hashmap varchar(max) , @heap varchar(max)
    -- this function is a wrapper for the steps of dijkstra's algo
    -- step 1 -- update the hashmap with the new cost 
    -- step 2 -- push the lower cost into the heap 
    -- step 3 -- return hashmap, and heap as the result 
    -- node_costs |A.100|B.200|C.300
    -- hashmap:  |A.0|B.99999|C.99999|D.99999|E.99999|F.99999|G.99999|H.99999
    -- heap: |A.0 
    
-- f_getNodeVal(@hashmap varchar(max), @node varchar(max))
    -- |A.0|B.99999|C.99999, B  --> 99999
    -- parameter: nodeX (|node.) , hashmap
    -- return: cost



-- For each heap popped head, it should only returns on line, and from that one line, the recursive CTE goes on 
-- Need to have a wrapper function - dijk to compute the compare and return logic
-- dijk (hash, heap, node, connected_nodes) --> return table, which has hash, heap as columns


----====================================================================================================================

--- Function input format - |nodeX.cost|nodeY.cost|.....

create or alter function f_initialize_hashmap(@nodeString varchar(max), @val bigint)
-- param: nodes (A,B,C,D,E), val
-- return hashmap |A.val|B.val... 

returns table as return 

with base as 
(select nodes = @nodeString ) -- union all select 'B' union all select 'C' )
select hashmap = '|' + STRING_AGG( concat_ws('.', node, @val), '|') 
from base 
    cross apply (select node = [value] from string_split(nodes, ',' ) ) cra
 

go 




create or alter function f_heappop(@heap varchar(max))
-- A.100|B.10|C.12 --> B.10
-- parameter: heapString
-- return string: heap_top, heap_rem
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

-- select * from f_heappop('|A.100')


go

create or alter function f_heappush(@heap varchar(max), @nodes_costs varchar(max))
--- f_heappush -- 500.D  --> @heap + @newNodeCost
-- parameter: heapString, new nodeX.Cost
-- return: heapString after concatenation
returns table as return 
with cte_heap as (
    select 
    node = PARSENAME([value], 2)
    , val = cast(PARSENAME([value], 1) as bigint)
    from string_split(@heap, '|') _
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
    node 
    , val
    from cte_heap h
    where node not in (select node from cte_updates) -- the nodes irrelevant to current updates
    or 
    exists (select * from cte_updates u where h.node = u.node and h.val < u.val) -- heap < current 
    union 
    select 
    node
    , val
    from cte_updates u
    where node not in (select node from cte_heap) -- new nodes
        or 
    exists (select * from cte_heap h where h.node = u.node and u.val < h.val) -- current is < heap
)
select 
heap = '|' + string_agg(CONCAT_WS('.', node, val), '|') within group (order by node)
from updated
go

-- select * from f_heappush('D.7', 'D.14|E.8')

-- node.cost


-- Costs - this is a hashmap, to store the lowest cost for current node 

-- the heap is used to get the lowest cost for all the nodes, and iterate for all the nodes connecting to it


-- for each node, initiate like 'node1.cost|node2.cost'

-- get from costs, check if current node cost is < nodex.cost


-- getFromSet 
-- parameter: setString, nodeX
-- return nodeX.cost

go 


create or alter function f_getNodeVal(@hashmap varchar(max), @node varchar(max))
-- |A.0|B.99999|C.99999, B  --> 99999
-- parameter: nodeX (|node.) , hashmap
-- return: cost
returns table as return 
with cte as 
(select rem = right(@hashmap, len(@hashmap) - CHARINDEX('|' + @node + '.', @hashmap)))
select cost = cast (
              case when CHARINDEX('|', rem) = 0 then PARSENAME(rem, 1)  -- the last part, it does not have the | in the end
                   else SUBSTRING(@hashmap
                                    , CHARINDEX('|' + @node+'.', @hashmap) + datalength(@node) + 2  -- from this location
                                    , CHARINDEX('|', rem) - datalength(@node) - 2
                                    )   
              end 
            as bigint)
from cte



go

-- select * from f_getNodeVal('|A.0|B.2|C.6|D.7|E.8|F.17|G.22|H.19', 'H')
--select * from f_getNodeVal('|A.0|B.99999|C.99999', 'H')
go 


create or alter function f_updateCost (@hashmap varchar(max), @nodes_costs varchar(max))
-- f_updateCost(|A.0|B.99999|C.199, '|A.200|B.300') --> |A.200|B.300|C.199
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


-- select * from f_updateCost('|A.0|B.2|C.6|D.7|E.99999|F.99999|G.99999|H.99999', 'D.14') _ 


create or alter function f_dijk(@nodes_costs varchar(max) -- node.cost|node.cost
                             , @hashmap varchar(max)
                             , @heap varchar(max)
                              )
returns table as return
--- this function is a wrapper for the steps of dijkstra's algo

-- step 1 -- update the hashmap with the new cost 
-- step 2 -- push the lower cost into the heap 
-- step 3 -- return hashmap, and heap as the result 

-- node_costs |A.100|B.200|C.300
-- hashmap:  |A.0|B.99999|C.99999|D.99999|E.99999|F.99999|G.99999|H.99999
-- heap: |A.0 
select hashmap, heap from f_updateCost(
                        @hashmap
                        , @nodes_costs) _update_hashmap -- update the hashmap 
                    cross apply 
                        f_heappush(
                        @heap
                        ,@nodes_costs
                    ) _heap_push


go





--=========================================================================================
--=========================================================================================
--=========================================================================================


drop table if exists #input


-- original example
-- SELECT 'A' AS Node1, 'B' AS Node2, 2 AS Cost into #input UNION SELECT 'A' AS Node1, 'C' AS Node2, 6 AS Cost UNION SELECT 'B' AS Node1, 'D' AS Node2, 5 AS Cost UNION SELECT 'C' AS Node1, 'D' AS Node2, 8 AS Cost UNION SELECT 'C' AS Node1, 'E' AS Node2, 2 AS Cost UNION SELECT 'D' AS Node1, 'F' AS Node2, 10 AS Cost UNION SELECT 'D' AS Node1, 'G' AS Node2, 15 AS Cost UNION SELECT 'G' AS Node1, 'F' AS Node2, 6 AS Cost UNION SELECT 'G' AS Node1, 'H' AS Node2, 6 AS Cost UNION SELECT 'F' AS Node1, 'H' AS Node2, 2 AS Cost UNION SELECT 'E' AS Node1, 'F' AS Node2, 20 AS Cost


SELECT 'A' AS Node1, 'B' AS Node2, 2 AS Cost into #input UNION ALL SELECT 'A', 'C', 6 UNION ALL SELECT 'B', 'D', 5 UNION ALL SELECT 'B', 'E', 3 UNION ALL SELECT 'C', 'D', 8 UNION ALL SELECT 'C', 'F', 4 UNION ALL SELECT 'D', 'G', 7 UNION ALL SELECT 'D', 'H', 6 UNION ALL SELECT 'E', 'I', 5 UNION ALL SELECT 'E', 'J', 9 UNION ALL SELECT 'F', 'J', 2 UNION ALL SELECT 'F', 'K', 8 UNION ALL SELECT 'G', 'L', 3 UNION ALL SELECT 'G', 'M', 4 UNION ALL SELECT 'H', 'M', 7 UNION ALL SELECT 'H', 'N', 5 UNION ALL SELECT 'I', 'O', 6 UNION ALL SELECT 'J', 'O', 3 UNION ALL SELECT 'J', 'P', 7 UNION ALL SELECT 'K', 'P', 2 UNION ALL SELECT 'K', 'Q', 5 UNION ALL SELECT 'L', 'Q', 4 UNION ALL SELECT 'L', 'R', 6 UNION ALL SELECT 'M', 'R', 5 UNION ALL SELECT 'N', 'S', 6 UNION ALL SELECT 'N', 'T', 8 UNION ALL SELECT 'O', 'U', 4 UNION ALL SELECT 'P', 'V', 6 UNION ALL SELECT 'Q', 'W', 7 UNION ALL SELECT 'R', 'X', 5 UNION ALL SELECT 'S', 'T', 3 UNION ALL SELECT 'S', 'Y', 7 UNION ALL SELECT 'T', 'Z', 6 UNION ALL SELECT 'U', 'V', 2 UNION ALL SELECT 'V', 'W', 4 UNION ALL SELECT 'W', 'X', 6 UNION ALL SELECT 'X', 'Y', 4 UNION ALL SELECT 'Y', 'Z', 3;

go


drop table if exists #dijk
-- from A to H
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
                cross apply (select hashmap from f_initialize_hashmap(nodes, 99999)) _ini
                cross apply (select hashmap from f_updateCost(hashmap, '|A.0')) _start_node
                 )
             as varchar(max)) 
, heap = cast( (select heap from f_heappush('','|A.0') _ ) as varchar(max))
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
            from f_heappop(c.heap) 
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
            from f_dijk(
                    _nodes_costs.nodes_costs
                    , c.hashmap
                    , _heap_top.heap_rem --c.heap
                    ) _
            ) _dijk


where c.heap != '' -- until the heap is all popped
-- and step < 5 
) 

select * into #dijk from cte 
option (maxrecursion 0)



select paths ='A --> Z', cost 
from #dijk 
cross apply (select * from f_getNodeVal(hashmap, 'Z')) _ 
where ISNULL(heap, '') = ''
 


