/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */
select name 
from Facilities 
WHERE membercost > 0.0;

/* Q2: How many facilities do not charge a fee to members? */
select count(facid) 
from Facilities 
WHERE membercost = 0.0;

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */
SELECT facid,
	   name,
	   membercost,
       monthlymaintenance 
FROM Facilities 
WHERE membercost > 0.0 and membercost < (monthlymaintenance * 0.20);

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */
SELECT * FROM Facilities where facid IN (1,5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */
SELECT name, 
	   monthlymaintenance,
	   case when monthlymaintenance > 100 then 'expensive'
			else 'cheap'
			end as monthlymaintenance_label
FROM Facilities;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */
SELECT firstname,
	   surname 
FROM Members 
WHERE joindate = (select max(joindate) from Members) and memid != 0;

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */
SELECT CONCAT( mem.Firstname, ' ', mem.surname ) AS Member_Name, fac.name AS Facility_Name
FROM 
Members AS mem, 
Facilities AS fac, 
(SELECT DISTINCT facid, memid
FROM Bookings
WHERE facid
IN (
SELECT facId
FROM Facilities
WHERE name LIKE 'Tennis Court%')) AS book
WHERE mem.memid = book.memid
AND fac.facid = book.facid
AND mem.memid != 0
ORDER BY Member_Name, Facility_Name

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */
select 
f.name as Facility_Name,
CASE WHEN b.memid = 0 then m.firstname 
	 else concat(m.firstname,' ',m.surname)
	 end as Member_Name,
case when b.memid = 0 then b.slots * f.guestcost
	 else b.slots * f.membercost
	 end as Cost
from Bookings as b
inner join Members as m on m.memid = b.memid
inner join Facilities as f on f.facid = b.facid
where DATE(starttime) = '2012-09-14'
and 
(case when b.memid = 0 then b.slots * f.guestcost
	 else b.slots * f.membercost
	 end) > 30
order by cost desc;

/* Q9: This time, produce the same result as in Q8, but using a subquery. */
select * from
(select 
f.name as Facility_Name,
CASE WHEN b.memid = 0 then m.firstname 
	 else concat(m.firstname,' ',m.surname)
	 end as Member_Name,
case when b.memid = 0 then b.slots * f.guestcost
	 else b.slots * f.membercost
	 end as Cost
from 
Members as m,
Facilities as f,
(select * from Bookings where DATE(starttime) = '2012-09-14') as b
where m.memid = b.memid and f.facid = b.facid) as final 
where final.cost > 30 
order by cost desc;

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */
select * from 
(select 
fac.name as Facility_Name,
SUM(case when book.memid = 0 then book.slots * fac.guestcost
     else  book.slots * fac.membercost
	 end) as Total_Revenue
from 
Bookings as book 
inner join Facilities as fac on book.facid = fac.facid
group by facility_name) as final
where final.Total_Revenue < 1000
order by final.Total_Revenue;
/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */
select m1.memid as Member_ID, (m1.surname || ',' || m1.firstname) as Memeber_Name, 
(select 
(m2.surname || ',' || m2.firstname) from Members m2 where m2.memid = m1.recommendedby) as Recommended_by 
from Members m1
where m1.memid != 0 
order by Memeber_Name

/* Q12: Find the facilities with their usage by member, but not guests */
--Facilities Total Usage
select fac.name as Facility_Name, COUNT(book.bookid) as Usage 
from Bookings as Book 
inner join Facilities as fac on fac.facid = book.facid 
where book.memid != 0 
group by Facility_Name
order by Usage desc;

--Facilities Usage by individial MEMBER
select (mem.firstname || ' ' || mem.surname) as Member_Name, fac.name as Facility_Name, COUNT(book.bookid) as Usage 
from Bookings as Book 
inner join Facilities as fac on fac.facid = book.facid 
inner join Members as mem on mem.memid = Book.memid
where book.memid != 0 
group by Facility_Name,Member_Name
order by Member_Name,Usage desc;

/* Q13: Find the facilities usage by month, but not guests */
select strftime('%m',starttime) as Month_Number, fac.name as Facility_Name, COUNT(book.bookid) as Usage 
from Bookings as Book 
inner join Facilities as fac on fac.facid = book.facid 
where book.memid != 0 
group by Month_Number,Facility_Name
order by Month_Number,Usage desc;
