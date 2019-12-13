--select dbo.fun_prefix('378612067300244564')  
  
CREATE function fun_prefix(    
  @sscc varchar(20)        
)    
    
returns varchar(20)     
    
as    
 begin    
    declare @primerCaracter varchar(2)
	set @primerCaracter = (SELECT STUFF(@sscc, 2, 20, ''))

	declare @segundoCaracter varchar(20)
	set @segundoCaracter = (SELECT STUFF(@sscc, 1, 9, ''))


	declare @tercerCaracter varchar(20)
	set @tercerCaracter = (SELECT STUFF(@segundoCaracter, 9, 9, ''))

	declare @concatenarCaracter varchar(20)
	set @concatenarCaracter = (SELECT CONCAT(@tercerCaracter,@primerCaracter))

	return @concatenarCaracter
     
 end    
  