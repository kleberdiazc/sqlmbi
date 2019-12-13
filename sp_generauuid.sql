--
--declare @uuid varchar(255)
--exec fun_retornauuid '91728','5277','S 1789','2019','ARP',@uuid out
--select @uuid
  
alter procedure fun_retornauuid(    
	@lote numeric(18,0), 
	@producto varchar(200),
	@embarque varchar(200),
	@anio varchar(10),
	@tipo varchar(5),
	@PalletD varchar (255) = null,
	@uuidRetorno  varchar(255) output   
)    
    

    
as    
 begin    
   
	if (@tipo = 'ARP')
	begin
		IF EXISTS (SELECT * FROM tb_uuidGen where uid_lote =  @lote and uid_tipo = @tipo) 
		BEGIN
		  set @uuidRetorno = (SELECT uid_uuid  FROM tb_uuidGen where uid_lote  =  @lote and uid_tipo = @tipo)
		END
		ELSE
		BEGIN
		   set @uuidRetorno =  (select 'urn:uuid:'+ convert(varchar(150),NEWID()))
		   insert into tb_uuidGen values(@lote,@uuidRetorno,@producto,@embarque,@anio,@tipo,null)
		END
	End
	if (@tipo = 'LTS')
	begin

		IF EXISTS (SELECT * FROM tb_uuidGen where uid_lote =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto) 
		BEGIN
		  set @uuidRetorno = (SELECT uid_uuid  FROM tb_uuidGen where uid_lote  =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto and uid_tipo = @tipo)
		END
		ELSE
		BEGIN
		   set @uuidRetorno =  (select 'urn:uuid:'+ convert(varchar(150),NEWID()))
		   insert into tb_uuidGen values(@lote,@uuidRetorno,@producto,@embarque,@anio,@tipo,null)
		END

	End
	if (@tipo = 'EMC')
	begin

		IF EXISTS (SELECT * FROM tb_uuidGen where uid_lote =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto) 
		BEGIN
		  set @uuidRetorno = (SELECT uid_uuid  FROM tb_uuidGen where uid_lote  =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto and uid_tipo = @tipo)
		END
		ELSE
		BEGIN
		   set @uuidRetorno =  (select 'urn:uuid:'+ convert(varchar(150),NEWID()))
		   insert into tb_uuidGen values(@lote,@uuidRetorno,@producto,@embarque,@anio,@tipo,null)
		END

	End
	if (@tipo = 'CGL')
	begin

		IF EXISTS (SELECT * FROM tb_uuidGen where uid_lote =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto) 
		BEGIN
		  set @uuidRetorno = (SELECT uid_uuid  FROM tb_uuidGen where uid_lote  =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto and uid_tipo = @tipo)
		END
		ELSE
		BEGIN
		   set @uuidRetorno =  (select 'urn:uuid:'+ convert(varchar(150),NEWID()))
		   insert into tb_uuidGen values(@lote,@uuidRetorno,@producto,@embarque,@anio,@tipo,null)
		END

	End
	if (@tipo = 'MST')
	begin

		IF EXISTS (SELECT * FROM tb_uuidGen where uid_lote =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto) 
		BEGIN
		  set @uuidRetorno = (SELECT uid_uuid  FROM tb_uuidGen where uid_lote  =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto and uid_tipo = @tipo)
		END
		ELSE
		BEGIN
		   set @uuidRetorno =  (select 'urn:uuid:'+ convert(varchar(150),NEWID()))
		   insert into tb_uuidGen values(@lote,@uuidRetorno,@producto,@embarque,@anio,@tipo,null)
		END

	End
	if (@tipo = 'OEB')
	begin

		IF EXISTS (SELECT * FROM tb_uuidGen where uid_lote =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto) 
		BEGIN
		  set @uuidRetorno = (SELECT uid_uuid  FROM tb_uuidGen where uid_lote  =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto and uid_tipo = @tipo)
		END
		ELSE
		BEGIN
		   set @uuidRetorno =  (select 'urn:uuid:'+ convert(varchar(150),NEWID()))
		   insert into tb_uuidGen values(@lote,@uuidRetorno,@producto,@embarque,@anio,@tipo,null)
		END

	End
	if (@tipo = 'ECL')
	begin

		IF EXISTS (SELECT * FROM tb_uuidGen where uid_lote =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto and uid_pallet = @PalletD) 
		BEGIN
		  set @uuidRetorno = (SELECT uid_uuid  FROM tb_uuidGen where uid_lote  =  @lote and uid_tipo = @tipo AND uid_embarque = @embarque and uid_producto = @producto and uid_tipo = @tipo and uid_pallet = @PalletD)
		END
		ELSE
		BEGIN
		   set @uuidRetorno =  (select 'urn:uuid:'+ convert(varchar(150),NEWID()))
		   insert into tb_uuidGen values(@lote,@uuidRetorno,@producto,@embarque,@anio,@tipo,@PalletD)
		END

	End
     
 end     

 select * from tb_uuidGen
  