
|column|
--------
|  1   |
|  3   |
|  5   |
|  9   |


declare @results varchar(500)

select @results = coalesce(@results + ',', '') +  convert(varchar(12),col)
from t
order by col

select @results as results

| RESULTS |
-----------
| 1,3,5,9 |





---



SELECT (email + ';') AS 'text()' FROM dbo.person_mailing_list
WHERE do_not_send = 0
FOR Xml PATH ('')