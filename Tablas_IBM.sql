--CREATE TABLE tb_uuid (
--    uuCod int,
--    uuID varchar(255),
--);

----insert into tb_uuid values (1,'ef8670a7-3bfe-4814-90ae-3719cad9ce7f')

--CREATE TABLE tb_instalacionesIBM (
--    ibm_codigo int IDENTITY(1,1) PRIMARY KEY,
--	ibm_codpro numeric(18,0), 
--    ibm_inst varchar(255) NOT NULL,
--    ibm_prefix varchar(255),
--);

--insert into tb_instalacionesIBM values (118,'KAMACLUSA','urn:ibm:ift:location:loc:78612067.wbCC')


--select * from tb_produc

--CREATE TABLE tb_productosIBM (
--    pri_codigo int IDENTITY(1,1) PRIMARY KEY,
--	pri_codcor numeric(18,0), 
--    pri_desc varchar(255) NOT NULL,
--	pri_cadenaUrn varchar(255),
--	pri_prefijoSonga varchar(100),
--    pri_prefix varchar(255),
--	pri_prefix_master varchar(255)
--);

--drop table tb_productosIBM


--insert into tb_productosIBM values (0,'Camaron Sin Clasificar','urn:ibm:ift:product:lot:class:','78612067','AMKs','')

--select * from tb_produc

----alter table tb_productosIBM add pri_prefix_llega varchar(255)

--update tb_productosIBM set pri_prefix_llega = 'QnyE';



drop table tb_uuidGen

CREATE TABLE tb_uuidGen (
    uid_codigo int IDENTITY(1,1) PRIMARY KEY,
	uid_lote numeric(18,0), 
    uid_uuid varchar(255) NOT NULL,
	uid_producto varchar(200),
	uid_embarque varchar(200),
	uid_anio varchar(10),
	uid_tipo varchar(10),
	uid_pallet varchar(255)
);

CREATE TABLE tb_prefijosIBM(
    pre_codigo int IDENTITY(1,1) PRIMARY KEY,
	pre_prempresa varchar(50),
	pre_preprefix varchar(250)
);

insert into tb_prefijosIBM values('78612067','urn:ibm:ift:lpn:obj:')