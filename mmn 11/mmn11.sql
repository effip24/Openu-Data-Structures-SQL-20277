

-- Question A -------------------------------------------------------------------
create table Product(
  code int,
  pname varchar(30),
  descr varchar(50),
  utype varchar(30),
  uprice float,
  manu varchar(30),
  sid int,
  primary key(code)
);

create table Branch(
  bid int,
  bname varchar(30),
  baddress varchar(50),
  primary key(bid)
);

create table Stock(
  code int,
  bid int,
  units float,
  primary key(code,bid),
  foreign key(bid) references Branch
);

create table Receipt(
  bid int,
  rdate date,
  rtime time,
  ptype varchar(30),
  total float default 0,
  primary key(bid,rdate,rtime),
  foreign key(bid) references Branch
);

create table Purchase(
  bid int,
  rdate date,
  rtime time,
  code int,
  units float check(units > 0),
  primary key(bid,rdate,rtime,code),
  foreign key(bid,rdate,rtime) references Receipt,
  foreign key(code) references Product
);

create table Supplier(
  sid int,
  sname varchar(30),
  address varchar(50),
  phone numeric(9,0),
  primary key(sid)
);
--------------------------------------------------------------------------------


-- Question B ------------------------------------------------------------------
create trigger T1
before insert
on Purchase
for each row
execute procedure trigf1();


create or replace function trigf1() returns trigger as $$

declare quantity int;
declare totalUpdate float;

begin

  select Stock.units
  from Stock into quantity
  where Stock.bid = new.bid;

  select (new.units * Product.uprice)
  from Product into totalUpdate
  where new.code = Product.code;

  if(new.units > quantity)
    then
    raise notice 'Error, out of stock!';
    return null;

  else
    update Stock set units = (units - new.units)
      where new.bid = Stock.bid and new.code = Stock.code;

    update Receipt set total = totalUpdate + total
      where new.bid = Receipt.bid and new.rdate = Receipt.rdate
      and new.rtime = Receipt.rtime;
    end if;

  return new;

end;

$$ language 'plpgsql';
--------------------------------------------------------------------------------


-- Question C ------------------------------------------------------------------
insert into Product(code, pname, descr, utype, uprice, manu, sid) values
  (987,'Tomatos','Vegetable','Kg',5.99,'manufacturer1',111),
  (876,'Cucumbers','Vegetable','Kg',4.99,'manufacturer2',222),
  (765,'Cornflakes','Cornflakes','Box',15.9,'manufacturer2',222),
  (654,'Camambert','Cheese','Box',12.50,'manufacturer2',111),
  (543,'Sweet Potato','Vegetable','Kg',16.40,'manufacturer3',333),
  (432,'Red pepper','Vegetable','Kg',15.99,'manufacturer1',111);

insert into Branch(bid, bname, baddress) values
(989,'tel aviv','road 1 tel aviv'),
(878,'Raanana','road 2 Raanana'),
(767,'Holon','road 3 Holon');

insert into Stock(code, bid, units) values
  (987,989,50),
  (987,878,75),
  (987,767,100),

  (876,989,30),
  (876,878,60),
  (876,767,25),

  (765,989,20),
  (765,878,15),

  (654,878,10),
  (654,767,5),

  (543,989,50),
  (543,767,165),

  (432,989,17),
  (432,878,25),
  (432,767,30);

insert into Receipt(bid, rdate, rtime, ptype, total) values
  (989,'18.3.20','10:00','Cash',0),
  (989,'16.8.20','12:30','Credit',0),
  (989,'16.7.20','12:00','Credit',0),
  (989,'15.7.20','15:35','Credit',0),

  (878,'17.3.20','8:30','Cash',0),
  (878,'22.7.20','7:00','Credit',0),

  (767,'13.7.20','22:00','Cash',0),
  (767,'10.3.20','20:30','Cash',0),
  (767,'14.5.20','14:25','Credit',0);

insert into Purchase(bid, rdate, rtime, code, units) values
  (989,'18.3.20','10:00',987,5),
  (989,'18.3.20','10:00',876,3),
  (989,'18.3.20','10:00',543,4),
  (989,'18.3.20','10:00',432,1),

  (878,'17.3.20','8:30',654,1),
  (878,'17.3.20','8:30',432,3),

  (767,'10.3.20','20:30',654,2),
  (767,'10.3.20','20:30',543,3);



insert into Supplier(sid, sname, address, phone) values
  (111,'supplier2','road 2 tel aviv',111111111),
  (222,'supplier3','road 2 jerusalem',222222222),
  (333,'supplier4','road 2 eilat',333333333);
------------------------------------------------------------------------------

-- Question D1 -----------------------------------------------------------------
select p.code, p.pname
from Product p
where p.manu ='manufacturer2' and p.uprice > 10;
--------------------------------------------------------------------------------

-- Question D2 -----------------------------------------------------------------
select p.pname, s.sname
from Product p, Supplier s
where p.descr = 'Vegetable' and p.uprice > 15 and p.sid = s.sid;
--------------------------------------------------------------------------------


-- Question D3 -----------------------------------------------------------------
select distinct p1.bid, p1.rdate, p1.rtime
from Purchase p1
group by p1.bid, p1.rdate, p1.rtime
having count(*) < 3 and
EXTRACT(MONTH FROM p1.rdate) = EXTRACT(MONTH FROM CURRENT_DATE)
and EXTRACT(YEAR FROM p1.rdate) = EXTRACT(YEAR FROM CURRENT_DATE);
--------------------------------------------------------------------------------


-- Question D4 -----------------------------------------------------------------
select p1.pname, s.sname
from Product p1, Supplier s
where p1.sid = s.sid and p1.sid in
(
  select p2.sid
  from Product p2
  group by  p2.sid
  having count(*) = 1
);
--------------------------------------------------------------------------------


-- Question D5 -----------------------------------------------------------------
select r2.bid, b.bname
from
(
  select r1.bid, sum(r1.total) as total
  from Receipt r1
  group by r1.bid
) as r2, Branch b
where r2.bid = b.bid and r2.total in
(
  select max(r4.total) as total
  from
  (
    select r3.bid, sum(r3.total) as total
    from Receipt r3
    group by r3.bid
  ) as r4
);
--------------------------------------------------------------------------------


-- Question D6 -----------------------------------------------------------------
select b.bid, b.bname
from Branch b
where b.bid in
(
  select s.bid
  from Stock s
  group by s.bid
  having count(s.bid) =
  (
    select count(p.code)
    from Product p
  )
);
--------------------------------------------------------------------------------

-- Question D7 -----------------------------------------------------------------
select Temp.bid, Temp.rdate, Temp.rtime
from
(
  select distinct p2.bid, p2.rdate, p2.rtime, count(distinct pr1.sid) as total
  from
  (
    (select p1.bid, p1.rdate, p1.rtime
      from Purchase p1
    )
    except
    (select  p1.bid, p1.rdate, p1.rtime
      from Purchase p1
      where p1.code = '876'
    )
  ) as p2,
  Purchase p3,
  Receipt r1,
  Product pr1
  where p2.bid = p3.bid and p2.rdate = p3.rdate and p2.rtime = p3.rtime and
  p2.bid = r1.bid and p2.rdate = r1.rdate and p2.rtime = r1.rtime
  and r1.total > 50 and p3.code = pr1.code
  group by p2.bid, p2.rdate, p2.rtime
) as Temp
where Temp.total =
(
  select min(p.total)
  from
  (
    select distinct p2.bid, p2.rdate, p2.rtime, count(distinct pr1.sid) as total
    from (
      (select p1.bid, p1.rdate, p1.rtime
        from Purchase p1
      )
      except
      (select  p1.bid, p1.rdate, p1.rtime
        from Purchase p1
        where p1.code = '876'
      )
    ) as p2,
    Purchase p3,
    Receipt r1,
    Product pr1
    where p2.bid = p3.bid and p2.rdate = p3.rdate and p2.rtime = p3.rtime and
    p2.bid = r1.bid and p2.rdate = r1.rdate and p2.rtime = r1.rtime
    and r1.total > 50 and p3.code = pr1.code
    group by p2.bid, p2.rdate, p2.rtime
  ) as p
);
--------------------------------------------------------------------------------
