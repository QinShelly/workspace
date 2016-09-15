

--select out the records for: 

--same room be ordered by same person in 5 continuous days

--Friday and Monday are continuous.

CREATE   VIEW dbo.vwRoomReservationForecast

AS

select tblRoom.RoomName,

a.[Owner],  

a.[Eventdate],

substring(convert(varchar,a.[fromtime],120),12,5) + '--' + substring(convert(varchar,a.[endtime],120),12,5) as [Time],  

Category, 

a.[Purpose]

from tblReservation a,(

select Owner,RoomID,eventDate,eventDate1=(

select min(eventDate) from tblReservation aa

where Owner=a.Owner and RoomID = a.RoomID and eventDate>=a.eventDate

and not exists(

select * from tblReservation 

where Owner=aa.Owner and RoomID = aa.RoomID

and datediff(day,aa.eventDate,eventDate)

=case datepart(dw,aa.eventDate)

when 6 then 3

when 7 then 2

else 1 end))

 

from tblReservation a

where not exists(

select * from tblReservation 

where Owner=a.Owner and RoomID = a.RoomID

and datediff(day,eventDate,a.eventDate)

=case datepart(dw,a.eventDate)

when 1 then 2

when 2 then 3

else 1 end)

and a.eventDate >= getdate()-60 and a.eventDate <= getdate() + 31

)b,tblRoom,tblCategory 

where a.Owner=b.Owner and a.RoomID = b.RoomID 

and a.RoomID = tblRoom.RoomCode 

and tblRoom.Available = 1

and a.type = tblCategory.[ID]

and a.eventDate between b.eventDate and b.eventDate1

and datediff(day,b.eventDate,b.eventDate1)>=4

and a.eventDate >= getdate() and a.eventDate <= getdate() + 31
