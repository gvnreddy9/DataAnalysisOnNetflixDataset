create database project;
create table project.test(id integer,name varchar(255));
select * from project.test;
insert into project.test(id, name) value(1,'gvnr'),(2,'gvnreddy'),(3,'king');

create TABLE project.netflix_raw(
	show_id varchar(10) primary key,
	type varchar(10) NULL,
	title nvarchar(200) NULL,
	director varchar(250) NULL,
	cast varchar(1000) NULL,
	country varchar(150) NULL,
	date_added varchar(20) NULL,
	release_year int NULL,
	rating varchar(10) NULL,
	duration varchar(10) NULL,
	listed_in varchar(100) NULL,
	description varchar(500) NULL);
    
    
select* from project.netflix_raw;
select * from project.netflix_raw where show_id='s5023';

select show_id,COUNT(*) 
from project.netflix_raw
group by show_id 
having COUNT(*)>1;
  
select * from netflix_raw where title in (select title from netflix_raw group by title having count(*)>1) order by title;
select * from netflix_raw where upper(title) in 
(select upper(title) from netflix_raw group by (upper(title)) having count(*)>1)
 order by upper(title);
 
WITH cte AS (
  SELECT *,
  ROW_NUMBER() OVER (PARTITION BY title, type ORDER BY show_id) AS rnk
  FROM project.netflix_raw
) 
select * from cte where rnk =1;

WITH cte AS (
  SELECT *,
  ROW_NUMBER() OVER (PARTITION BY title, type ORDER BY show_id) AS rnk
  FROM project.netflix_raw
) 
select count(*) from cte where rnk =1;

#cross apply not working in My Sql 
select show_id, value as genre 
from netflix_raw 
cross apply string_split(director,',');

create table netflix_director(show_id varchar(20),name varchar(255));

select * from netflix_raw order by show_id;

# inserting data into netflix_country table by doing analysis

insert into netflix_country
select  show_id,m.country 
from netflix_raw nr
inner join (
select director,country
from  netflix_country nc
inner join netflix_directors nd on nc.show_id=nd.show_id
group by director,country
) m on nr.director=m.director
where nr.country is null;

------------------------
# and one more observation is where we saw the duration and rating is data not stored interchanged 
select * from project.netflix_raw where duration is null;

select *, case 
            when duration = null then rating 
            else duration
	        end as duration 
 from project.netflix_raw;
 
 select * from project.netflix_raw where duration is null;

==============================
with cte as (
select * 
,ROW_NUMBER() over(partition by title , type order by show_id) as rn
from project.netflix_raw
)
select show_id,type,title,cast(date_added as date) as date_added,release_year
,rating,case when duration is null then rating else duration end as duration,description
into netflix1
from cte ;

# with out into working may be we need to pre define a table in MySql
WITH cte AS (
  SELECT *,
  ROW_NUMBER() OVER (PARTITION BY title, type ORDER BY show_id) AS rnk
  FROM project.netflix_raw
) 
select show_id,type,title,cast(date_added as date) as date_added,release_year
,rating,case when duration is null then rating else duration end as duration,description 
from cte where rnk =1 and date_added is null;

WITH cte AS (
  SELECT *,
  ROW_NUMBER() OVER (PARTITION BY title, type ORDER BY show_id) AS rnk
  FROM project.netflix_raw
) 
select show_id,type,title,cast(date_added as date) as date_added,release_year
,rating,case when duration is null then rating else duration end as duration,description 
into netflix
from cte ; # ---> Error Code: 1327. Undeclared variable: netflix	0.000 sec
=====================================

#                             --netflix data analysis

/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */


select director, 
count(*) as count, 
count(distinct case when n.type ='TV Show' then n.show_id end) as No_TVShow, 
count(distinct case when n.type = 'Movie' then n.show_id end) as No_Movie  
from netflix n  
join netflix_directors nd on n.show_id = nd.show_id
group by director order by count desc ;

/*--2 which country has highest number of comedy movies */

select  country,count(distinct ng.show_id)as genre  from netflix n  
join netflix_genre ng on n.show_id = ng.show_id
join netflix_country nc on ng.show_id = nc.show_id
where genre = 'Comedies' and n.type='Movie'
group by country 
order by genre desc ;

/*--3 for each year (as per date added to netflix), which director has maximum number of movies released  */

with cte1 as(
select nd.director,n.release_year, count(n.show_id) cnt
from netflix n
join netflix_directors nd on n.show_id = nd.show_id
where type='Movie'
group by nd.director,n.release_year
), 
cte2 as(
select director,release_year,cnt,
ROW_NUMBER() over(partition by release_year order by cnt desc) rnk
from cte1
)
select * from cte2 where rnk =1;

/*--4 what is average duration of movies in each genre*/

select ng.genre, AVG(CAST(REPLACE(n.duration, ' min', '') AS UNSIGNED)) as minit 
from netflix n 
join netflix_genre ng on n.show_id = ng.show_id
where type='Movie'
group by ng.genre;

/*--5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them  */

select nd.director,
count(distinct case when ng.genre='Comedies' then n.show_id end) as comedy_movies,
count(distinct case when ng.genre='Horror Movies' then n.show_id end) as horror_movies
from netflix n 
join netflix_genre ng on n.show_id = ng.show_id
join netflix_directors nd on ng.show_id = nd.show_id
where type='Movie' and ng.genre in ('Comedies','Horror Movies')
group by nd.director
having count(distinct ng.genre) = 2
;

select nd.director
, count(distinct case when ng.genre='Comedies' then n.show_id end) as no_of_comedy 
, count(distinct case when ng.genre='Horror Movies' then n.show_id end) as no_of_horror
from netflix n
inner join netflix_genre ng on n.show_id=ng.show_id
inner join netflix_directors nd on n.show_id=nd.show_id
where type='Movie' and ng.genre in ('Comedies','Horror Movies')
group by nd.director
having COUNT(distinct ng.genre)=2;
