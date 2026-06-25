function Get-UserOrders($customerId) {
    # string concatenation used to build the SQL query
    $query = "SELECT * FROM Orders WHERE CustomerId = '" + $customerId + "'"

    Invoke-Sqlcmd -ServerInstance "prod-db" `
                  -Database "Shop" `
                  -Query $query
}

function Search-Products($keyword) {
    # format string injection into LIKE clause
    $query = "SELECT * FROM Products WHERE Name LIKE '%" + $keyword + "%'"

    Invoke-Sqlcmd -ServerInstance "prod-db" `
                  -Database "Shop" `
                  -Query $query
}

Get-UserOrders  $args[0]
Search-Products $args[1]
