-- Starting Query
-- SELECT * FROM c

-- Select specific fields
-- SELECT o.CustomerName, o.OrderDate, o.OrderDetails FROM orders o

-- Select orders for a specific customer (partition key)
SELECT o.CustomerName, o.OrderDate, o.OrderDetails 
FROM orders o  
WHERE o.CustomerName = 'Sarah'

-- Select orders for Pineapple Pizza
SELECT o.CustomerName, o.OrderDate, o.OrderDetails
FROM orders o
JOIN od in o.OrderDetails
WHERE od.ItemName = 'Pineapple Pizza'

-- Select orders for Pineapple Pizza or Cheese Pizza
SELECT o.CustomerName, o.OrderDate, o.OrderDetails
FROM orders o
JOIN od in o.OrderDetails
WHERE od.ItemName IN ('Pineapple Pizza','Cheese Pizza')

-- Who is ordering Pineapple Pizza?
SELECT DISTINCT o.CustomerName
FROM orders o
JOIN od in o.OrderDetails
WHERE od.ItemName = 'Pineapple Pizza'

-- How many orders are there for Pineapple Pizza?
SELECT COUNT(o.OrderId)
FROM orders o
JOIN od in o.OrderDetails
WHERE od.ItemName = 'Pineapple Pizza'

-- Who is ordering more than 2 of a pizza?
SELECT DISTINCT o.CustomerName
FROM orders o
JOIN od in o.OrderDetails
WHERE od.Qty > 2

-- What are those orders?
SELECT o.CustomerName, o.OrderDate, o.OrderDetails
FROM orders o
JOIN od in o.OrderDetails
WHERE od.Qty > 2