select
    step as "Этап",
    count(distinct user_id) as "Количество пользователей"
from events
group by step
order by 
    case step 
        when 'visit' then 1 
        when 'view_item' then 2 
        when 'cart' then 3 
        when 'purchase' then 4 
    end;