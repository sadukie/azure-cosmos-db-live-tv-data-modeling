/* Cleanup
DROP TABLE OrderDetails
DROP TABLE Items
DROP TABLE Orders
DROP TABLE Customers
*/

-- Create the relational tables

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE dbo.Customers(
	CustomerId int IDENTITY(1,1) NOT NULL,
	Name varchar(50) NOT NULL,
    CONSTRAINT PK_Customers_CustomerId PRIMARY KEY (CustomerId)
) ON [PRIMARY]
GO

CREATE TABLE dbo.Orders(
	OrderId int IDENTITY(1,1) NOT NULL,
    CustomerId int NOT NULL,
	OrderDate datetime NOT NULL DEFAULT(GETDATE()),
    CONSTRAINT PK_Orders_OrderId PRIMARY KEY (OrderId),
    FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId)
) ON [PRIMARY]
GO

CREATE TABLE dbo.Items(
    ItemId int IDENTITY(1,1) NOT NULL,
    Name varchar(50) NOT NULL,
    Description varchar(100) NULL,
    UnitPrice decimal(9,2) NOT NULL,
    CONSTRAINT PK_Items_ItemId PRIMARY KEY (ItemId)
) ON [PRIMARY]
GO

CREATE TABLE dbo.OrderDetails(
    OrderId int NOT NULL,
    OrderLineId int NOT NULL,
    UnitPrice decimal(9,2) NOT NULL,
    Qty int NOT NULL,
    ItemId int NOT NULL,
    CONSTRAINT PK_OrderDetails PRIMARY KEY (OrderId, OrderLineId),
    FOREIGN KEY (ItemId) REFERENCES Items(ItemId)
) ON [PRIMARY]
GO

-- Populate Data

-- Customers
SET IDENTITY_INSERT [Customers] ON
INSERT INTO Customers (CustomerId,Name) VALUES (1,'Sarah'), (2,'Mark'), (3,'Matt'), (4,'Jeff'), (5,'Carey')
SET IDENTITY_INSERT [Customers] OFF
GO

-- Items
SET IDENTITY_INSERT [Items] ON
INSERT INTO Items (ItemId, Name, Description, UnitPrice) VALUES
    (1, 'Cheese Pizza','just cheese - no other toppings needed.',10.99),
    (2, 'You Name It Pizza','Beans, greens, potatoes, tomatoes...',19.99),
    (3, 'Pineapple Pizza','For the pineapple lover who can eat it on their pizza',12.99),
    (4, 'Veggie Pizza','Onions, peppers, tomatoes, olives, etc.',17.99),
    (5, 'Apple Pizza','Drizzled with icing.',19.99)    
SET IDENTITY_INSERT [Items] OFF

-- Orders
SET IDENTITY_INSERT [Orders] ON
INSERT INTO Orders (OrderId,CustomerId,OrderDate) VALUES
(1,1,'2022-03-01 14:19:08.00'),
(2,2,'2022-03-01 14:30:20.00'),
(3,3,'2022-03-01 16:50:11.00'),
(4,1,'2022-03-03 18:00:46.00'),
(5,4,'2022-03-03 19:00:53.00'),
(6,1,'2022-03-10 18:43:01.00'),
(7,2,'2022-03-10 19:11:23.00'),
(8,5,'2022-03-17 20:18:03.00'),
(9,1,'2022-03-24 16:30:05.00')
SET IDENTITY_INSERT [Orders] OFF
GO

-- OrderDetails
INSERT INTO OrderDetails
SELECT 1, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*5), ItemId FROM Items WHERE Name IN ('Cheese Pizza','Pineapple Pizza','You Name It Pizza','Apple Pizza')

INSERT INTO OrderDetails
SELECT 2, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*4), ItemId FROM Items WHERE Name IN ('Veggie Pizza','Apple Pizza')

INSERT INTO OrderDetails
SELECT 3, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*4), ItemId FROM Items WHERE Name IN ('Cheese Pizza')

INSERT INTO OrderDetails
SELECT 4, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*4), ItemId FROM Items WHERE Name IN ('You Name It Pizza','Apple Pizza')

INSERT INTO OrderDetails
SELECT 5, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*4), ItemId FROM Items WHERE Name IN ('You Name It Pizza','Apple Pizza')

INSERT INTO OrderDetails
SELECT 6, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*4), ItemId FROM Items WHERE Name IN ('Cheese Pizza','Pineapple Pizza','Apple Pizza')

INSERT INTO OrderDetails
SELECT 7, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*4), ItemId FROM Items WHERE Name IN ('Cheese Pizza','Apple Pizza')

INSERT INTO OrderDetails
SELECT 8, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*4), ItemId FROM Items WHERE Name IN ('You Name It Pizza','Apple Pizza')

INSERT INTO OrderDetails
SELECT 9, ROW_NUMBER() OVER(ORDER BY ItemId), UnitPrice, CEILING(RAND()*4), ItemId FROM Items WHERE Name IN ('Pineapple Pizza','You Name It Pizza')


-- Get all orders with descriptions
SELECT c.Name AS CustomerName, o.OrderId, OrderDate, OrderLineId, i.Name AS ItemName, od.UnitPrice, Qty
FROM Customers c
JOIN Orders o ON o.CustomerId = c.CustomerId
JOIN OrderDetails od ON od.OrderId = o.OrderId
JOIN Items i ON i.ItemId = od.ItemId

-- Get all orders with descriptions - JSON out for creating documents in document store
SELECT c.Name AS CustomerName, o.OrderId, OrderDate, 
    (SELECT OrderLineId, i.Name AS ItemName, Qty, od.UnitPrice 
    FROM OrderDetails od
    JOIN Items i ON i.ItemId = od.ItemId
    WHERE od.OrderId = o.OrderId
    FOR JSON PATH) AS [OrderDetails]
FROM Customers c
JOIN Orders o ON o.CustomerId = c.CustomerId
FOR JSON PATH

-- Create People Vertices
SELECT 'g.addV(''customer'').property(''name'','''+ Name + ''').property(''customerId'',' + CAST(CustomerId AS varchar(2)) + ').property(''type'',''customer'')' FROM Customers

-- Create relationships
SELECT 'g.V().has(''name'',''Sarah'').addE(''referred'').to(g.V().has(''name'',''Mark''))'
SELECT 'g.V().has(''name'',''Sarah'').addE(''referred'').to(g.V().has(''name'',''Matt''))'
SELECT 'g.V().has(''name'',''Sarah'').addE(''referred'').to(g.V().has(''name'',''Carey''))'

-- Create Item vertices
SELECT 'g.addV(''item'').property(''name'','''+ Name + ''').property(''itemId'',' + CAST(ItemId AS varchar(2)) + ').property(''description'',''' + Description + ''').property(''type'',''item'')' FROM Items

-- Add people and item relationships
SELECT DISTINCT 'g.V().hasLabel(''customer'').has(''name'',''' + c.Name + ''').addE(''bought'').to(g.V().hasLabel(''item'').has(''name'',''' + i.Name + '''))'
FROM Customers c
JOIN Orders o ON o.CustomerId = c.CustomerId
JOIN OrderDetails od ON od.OrderId = o.OrderId
JOIN Items i ON i.ItemId = od.ItemId