select 
	client_id, 
	cast(transaction_date as date), 
	count(distinct transaction_id) as count_tr
from transactions
where amount <10000
group by client_id, cast(transaction_date as date)
having count(distinct transaction_id) >=3;