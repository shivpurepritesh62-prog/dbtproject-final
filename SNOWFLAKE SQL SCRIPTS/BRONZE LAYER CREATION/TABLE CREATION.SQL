create or replace  database dbt_project_dev ;
create or replace schema bronze;
create or replace schema silver
create or replace schema gold 
create or replace transient table Address (
  AddressID string,
  AddressLine1 string,
  AddressLine2 string,
  City string,
  StateProvince string,
  CountryRegion string,
  PostalCode string,
  rowguid string,
  ModifiedDate string
);

CREATE OR REPLACE TRANSIENT TABLE SALESORDERHEADER (
    SalesOrderID              NUMBER(38,0),
    RevisionNumber            NUMBER(38,0),
    OrderDate                 TIMESTAMP_NTZ(7),
    DueDate                   TIMESTAMP_NTZ(7),
    ShipDate                  TIMESTAMP_NTZ(7),
    Status                    NUMBER(38,0),
    OnlineOrderFlag           BOOLEAN,
    SalesOrderNumber          VARCHAR,
    PurchaseOrderNumber       VARCHAR,
    AccountNumber             VARCHAR,
    CustomerID                NUMBER(38,0),
    ShipToAddressID           NUMBER(38,0),
    BillToAddressID           NUMBER(38,0),
    ShipMethod                VARCHAR,
    CreditCardApprovalCode    VARCHAR,
    SubTotal                  NUMBER(18,4),
    TaxAmt                    NUMBER(18,4),
    Freight                   NUMBER(18,4),
    TotalDue                  NUMBER(18,4),
    Comment                   VARCHAR,
    rowguid                   VARCHAR,
    ModifiedDate              TIMESTAMP_NTZ(7)
);

CREATE OR REPLACE TRANSIENT TABLE PRODUCTCATEGORY (
    ProductCategoryID          NUMBER(38,0),
    ParentProductCategoryID    NUMBER(38,0),
    Name                       VARCHAR,
    rowguid                    VARCHAR,
    ModifiedDate               TIMESTAMP_NTZ(7)
);

CREATE OR REPLACE TRANSIENT TABLE SALESORDERDETAIL (
    SalesOrderID          NUMBER(38,0),
    SalesOrderDetailID    NUMBER(38,0),
    OrderQty              NUMBER(38,0),
    ProductID             NUMBER(38,0),
    UnitPrice             NUMBER(18,4),
    UnitPriceDiscount     NUMBER(18,4),
    LineTotal              NUMBER(18,4),
    rowguid               VARCHAR,
    ModifiedDate          TIMESTAMP_NTZ(7)
);

CREATE OR REPLACE TRANSIENT TABLE PRODUCTMODELPRODUCTDESCRIPTION (
    ProductModelID          NUMBER(38,0),
    ProductDescriptionID    NUMBER(38,0),
    Culture                 VARCHAR,
    rowguid                 VARCHAR,
    ModifiedDate            TIMESTAMP_NTZ(7)
);

CREATE OR REPLACE TRANSIENT TABLE PRODUCTMODEL (
    ProductModelID       NUMBER(38,0),
    Name                 VARCHAR,
    CatalogDescription   VARCHAR,
    rowguid              VARCHAR,
    ModifiedDate         TIMESTAMP_NTZ(7)
);

CREATE OR REPLACE TRANSIENT TABLE PRODUCTDESCRIPTION (
    ProductDescriptionID    NUMBER(38,0),
    Description             VARCHAR,
    rowguid                 VARCHAR,
    ModifiedDate            TIMESTAMP_NTZ(7)
);

CREATE OR REPLACE TRANSIENT TABLE PRODUCT (
    ProductID                 NUMBER(38,0),
    Name                      VARCHAR,
    ProductNumber             VARCHAR,
    Color                     VARCHAR,
    StandardCost              NUMBER(18,4),
    ListPrice                 NUMBER(18,4),
    Size                      VARCHAR,
    Weight                    NUMBER(18,4),
    ProductCategoryID         NUMBER(38,0),
    ProductModelID            NUMBER(38,0),
    SellStartDate             TIMESTAMP_NTZ(7),
    SellEndDate               TIMESTAMP_NTZ(7),
    DiscontinuedDate          TIMESTAMP_NTZ(7),
    ThumbNailPhoto            VARCHAR,
    ThumbnailPhotoFileName    VARCHAR,
    rowguid                   VARCHAR,
    ModifiedDate              TIMESTAMP_NTZ(7)
);

CREATE OR REPLACE TRANSIENT TABLE CUSTOMERADDRESS (
    CustomerID      NUMBER(38,0),
    AddressID       NUMBER(38,0),
    AddressType     VARCHAR,
    rowguid         VARCHAR,
    ModifiedDate    TIMESTAMP_NTZ(7)
);

CREATE OR REPLACE TRANSIENT TABLE CUSTOMER (
    CustomerID       NUMBER(38,0),
    NameStyle        BOOLEAN,
    Title            VARCHAR,
    FirstName        VARCHAR,
    MiddleName       VARCHAR,
    LastName         VARCHAR,
    Suffix           VARCHAR,
    CompanyName      VARCHAR,
    SalesPerson      VARCHAR,
    EmailAddress     VARCHAR,
    Phone            VARCHAR,
    PasswordHash     VARCHAR,
    PasswordSalt     VARCHAR,
    rowguid          VARCHAR,
    ModifiedDate     TIMESTAMP_NTZ(7)
);