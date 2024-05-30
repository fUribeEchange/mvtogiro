IF @Tipo = 10 --> Nuevo Transferencia de Giro
	   BEGIN TRY 
	     --> Asignar HoraOpe del Servidor
		 SET @HoraOpe=SUBSTRING(CAST(SYSDATETIME() AS VARCHAR),12,8)
         EXEC WebApiFunction_HorarioPermitido @IdAgeOrigen,@HoraOpe,@xStatus OUTPUT,@xMessage OUTPUT,@xResult OUTPUT
		 -->
		 IF @xStatus<>'00'
		    BEGIN
		 	  SELECT @xResult,WNroOpe=0
			  Return
			END
		 --> Bloqueo Temporizador (Validacion) para Procesar la Orden
		 IF @Situacion='P' SELECT @Situacion=CASE WHEN CantMinBloqEch>0 THEN VarSitMvtoGiro ELSE @Situacion END FROM CONFIG 
         -->
		 BEGIN TRAN
		   --> Asignar IdAgePosicion Desde la Tabla AGENCIA
		   SELECT @IdAgePosicion=IdAgePosicion FROM AGENCIA WHERE IdAgencia=@IdAgeOrigen		
		   --> Control Stock y Costo Promedio 
		   SELECT @CostPromD=0,@CostPromT=0,@CostPromG=0
		   SELECT @CostPromG=TCVtaGiroAgente FROM STOCKDIVISA WHERE IdAgencia=@IdAgeOrigen AND IdDivisa='USD'
	       --> Generar Nro.Operacion
		   SELECT @NroOpe=NroOpe FROM PARAMETROS_NROOPE WHERE IdAgeOrigen=@WIdAgeOrigen AND IdAgeDestino=@WIdAgeNroOpe
		   UPDATE PARAMETROS_NROOPE SET NroOpe= NroOpe + 1 WHERE IdAgeOrigen=@WIdAgeOrigen AND IdAgeDestino=@WIdAgeNroOpe
		   --> Generar Nro.Documento Tributario
		   SELECT @IdDocTri=IdDocTriG,@NroDocTri=NDocTriActG,@SerDocTri=SerDocTriG FROM USUARIO WHERE IdUsuario=@IdUsuGen
		   UPDATE USUARIO SET NDocTriActG = NDocTriActG + 1 WHERE IdUsuario=@IdUsuGen
		   --> Genera Claves de Seguridad
		   EXEC WebApiFunction_ClaveGiro @FhaOpe,@IdAgeDestino,@NroOpe,@ClaveGiro OUTPUT
		   --> Genera Ean13Ehange
		   --IF SUBSTRING(@IdAgeOrigen,1,2)='12'
		   --  EXEC PA_WebApiFunction_Ean13Ech @IdRemit,@Ean13Unired OUTPUT
		   -->
		   --> Marcar El Registro Anulado por ReEnvio Tabla MVTOGIRANU
		   IF @RefNroOpe > 0 
			  UPDATE MVTOGIRANU 
				SET FhaReEnvio=@FhaOpe,RefNroOpe=@NroOpe,RefIdDocTri=@IdDocTri,RefNroDocTri=@NroDocTri,RefSerDocTri=@SerDocTri,Status='C'
				  WHERE NroOpe=@RefNroOpe AND IdDocTri=@RefIdDocTri AND NroDocTri=@RefNroDocTri AND SerDocTri=@RefSerDocTri
		   -->
		   SELECT @MxnUniteller=CASE WHEN IdEntCtaCte='F5' THEN 'True' ELSE 'False' END FROM EMPRESA WHERE IdEmpresa=SUBSTRING(@IdAgeDestino,1,2) 
		   -->
		   IF @IdEntCtaCte = '54' 
		      INSERT INTO CTRL_NROOPE(NroOpe,IdEntCtaCte,IdAgeOrigen) VALUES (@NroOpe,'50',@IdAgeOrigen)
		   ELSE
		      INSERT INTO CTRL_NROOPE(NroOpe,IdEntCtaCte,IdAgeOrigen) VALUES (@NroOpe,@IdEntCtaCte,@IdAgeOrigen)
		   -->
		   IF @IdEntCtaCte='56' --Uniteller
              INSERT INTO CTRL_KEYCORRESP(ClaveGiro,IdEntCtaCte,IdAgeOrigen) VALUES (@ClaveGiro,@IdEntCtaCte,@IdAgeOrigen)
		   -->
		   IF @IdEntCtaCte='54' --BANCO INTERBANK SOLES
		      SET @ImpAproxCob=@EImpGiro
		   -->
		   IF (SUBSTRING(@IdAgeOrigen,1,2) = '10' AND @ImpGiro >= 700) OR (@RemitPagoME > 0 AND @RemitPagoML = 0)
		      SELECT @Situacion='O'
		    -->
		   INSERT INTO MVTOGIRO(NroOpe,IdDocTri,NroDocTri,SerDocTri,IdAgeOrigen,IdAgeDestino,IdEntCtaCte,FhaOpe,HoraOpe,IdRemit,IdDesti,AnDesti,Mensaje,ImpGiro,
					   ImpCorresp,ImpAgente,ImpÙtilAgt,ImpUtilidad,ImpBancario,ImpRoundME,ImpTotal,CostPromD,CostPromT,AImpUtilAgt,CostPromG,TCVMEEnv,ImpRoundML,ImpTotalML,TCCMEEnv,
					   TotBolEmpML,ImpVtaEmpML,TotBolAgtML,ImpVtaAgtML,TCCAproxCob,ImpAproxCob,RemitPagoML,RemitPagoME,RemitVuelML,RemitVuelME,
					   DetaPagoML,DetaPagoME,Avisado,CondPago,ClaveGiro,NombreBco,PlazaBco,TipCtaBco,NroCtaBco,NroRutaBco,IbkCtaAbono,IbkTarjCred,Situacion,
					   FhaPago,NroRecPag,HoraPago,FormaPago,IdDivisaPag,TCDivisaPag,ImpGiroPag,IdAgePagado,ObsCorresp,SitCorresp,ObsSystem,ObsMsjSys,
					   RefNroOpe,RefIdDocTri,RefNroDocTri,RefSerDocTri,IdUsuGen,IdUsuAnu,IdUsuCan,IdUsuExt,IdUsuMod,IdUsuOfC,CtrEnvSys,CtrRetSys,NroRefCor,IdAgePosicion,
					   IdTPosUnired,Ean13Unired,TicketUnired,FhaPagUnired,HraPagUnired,SitUnired,ObsWsUnired,ComCobUnired,TotCobUnired,PagComUnired,StatusUnired,
					   FhaLiquidacion,SitValidacion,ObsValidacion,IdTotem,IdTicket,EImpGiro,EImpCorresp,EImpAgente,EImpUtilAgt,EImpUtilidad,EImpTotal)
			   VALUES (@NroOpe,@IdDocTri,@NroDocTri,@SerDocTri,@IdAgeOrigen,@IdAgeDestino,@IdEntCtaCte,@FhaOpe,@HoraOpe,@IdRemit,@IdDesti,@AnDesti,@Mensaje,@ImpGiro,
					   @ImpCorresp,@ImpAgente,@ImpUtilAgt,@ImpUtilidad,@ImpBancario,@ImpRoundME,@ImpTotal,@ImpGiro,@ImpCorresp,@ImpUtilAgt,@ImpUtilidad,@TCVMEEnv,@ImpRoundML,@ImpTotalML,@TCCMEEnv,
					   @TotBolEmpML,@ImpVtaEmpML,@TotBolAgtML,@ImpVtaAgtML,@TCCAproxCob,@ImpAproxCob,@RemitPagoML,@RemitPagoME,@RemitVuelML,@RemitVuelME,
					   @DetaPagoML,@DetaPagoME,@Avisado,@CondPago,@ClaveGiro,@NombreBco,@PlazaBco,@TipCtaBco,@NroCtaBco,@NroRutaBco,@IbkCtaAbono,@IbkTarjCred,@Situacion,
					   @FhaPago,@NroRecPag,@HoraPago,@FormaPago,@IdDivisaPag,@TCDivisaPag,@ImpGiroPag,@IdAgePagado,@ObsCorresp,@SitCorresp,@ObsSystem,@ObsMsjSys,
					   @RefNroOpe,@RefIdDocTri,@RefNroDocTri,@RefSerDocTri,@IdUsuGen,@IdUsuAnu,@IdUsuCan,@IdUsuExt,@IdUsuMod,@IdUsuOfC,@CtrEnvSys,@CtrRetSys,@NroRefCor,@IdAgePosicion,
					   @IdTPosUnired,@Ean13Unired,@TicketUnired,@FhaPagUnired,@HraPagUnired,@SitUnired,@ObsWsUnired,@ComCobUnired,@TotCobUnired,@PagComUnired,@StatusUnired,
					   @FhaLiquidacion,@SitValidacion,@ObsValidacion,@IdTotem,@IdTicket,@EImpGiro,@EImpCorresp,@EImpAgente,@EImpUtilAgt,@EImpUtilidad,@EImpTotal)
--		   SELECT WNroOpe=@NroOpe,WIdDocTri=@IdDocTri,WNroDocTri=@NroDocTri,WSerDocTri=@SerDocTri,ClaveGiro=@ClaveGiro,WCostPromD=@CostPromD,WCostPromT=@CostPromT,WCostPromG=@CostPromG 
		   --> Marcar Ticket como Procesado
		   --> UPDATE TICKET SET Status='2' WHERE IdTotem=@IdTotem AND IdTicket=@IdTicket
		   --> Registrar Movimiento Cuenta Corriente Corresponsal
		   IF SUBSTRING(@IdAgeDestino,1,2) IN ('54')
		      SET @Debe=@EImpGiro+@EImpCorresp
           ELSE
		      BEGIN
		        SET @Debe=@ImpGiro+@ImpCorresp
		        IF @MxnUniteller= 'True'
			       SET @EDebe=@EImpGiro+@EImpCorresp
			  END
		   -->
		   SET @DebeAgt=0
		   SET @SaldoAgt=0
		   IF @TipEmpresa='A' SET @DebeAgt=@ImpGiro+@ImpAgente
		   IF SUBSTRING(@IdAgeDestino,1,2) IN ('54')
		      UPDATE ENTCTACTE 
			    SET TotCargo=TotCargo+@Debe,TotSaldo=TotSaldo-@Debe,
		            ETotCargo=ETotCargo+@ImpGiro+@ImpCorresp,ETotSaldo=ETotSaldo-@ImpGiro-@ImpCorresp
				  WHERE IdEntCtaCte=@IdEntCtaCte
		   ELSE
		     BEGIN 
		       UPDATE ENTCTACTE SET TotCargo=TotCargo+@Debe,TotSaldo=TotSaldo-@Debe WHERE IdEntCtaCte=@IdEntCtaCte
               IF @MxnUniteller= 'True' 
                  UPDATE ENTCTACTE SET ETotCargo=ETotCargo+@EDebe,ETotSaldo=ETotSaldo-@EDebe WHERE IdEntCtaCte=@IdEntCtaCte
			 END
		   -->
		   SELECT @Saldo=TotSaldo,@ESaldo=ETotSaldo FROM ENTCTACTE WHERE IdEntCtaCte=@IdEntCtaCte 
		   IF @TipEmpresa='A' 
			  BEGIN
				UPDATE ENTCTACTE SET TotCargo=TotCargo+@DebeAgt,TotSaldo=TotSaldo-@DebeAgt WHERE IdEntCtaCte=@IdEntCtaCteAgt
				SELECT @SaldoAgt=TotSaldo FROM ENTCTACTE WHERE IdEntCtaCte=@IdEntCtaCteAgt 
			  END
		   -->	
		   SELECT @Origen=@IdAgeOrigen+' - '+PO.Descripcion+' '+AO.Ciudad,@Destino=@IdAgeDestino+' - '+PD.Descripcion+' '+AD.Ciudad
					 FROM AGENCIA AS AO,AGENCIA AS AD,PAIS AS PO,PAIS AS PD
			   WHERE AO.IdAgencia=@IdAgeOrigen AND AD.IdAgencia=@IdAgeDestino AND AO.IdPais=PO.IdPais AND AD.IdPais=PD.IdPais 
           --> Generacion Correlativo CtaCte
		   SET @cFhaOpe=CONVERT(Char(10),@FhaOpe,103)
		   SELECT @Correlativo=ISNULL(CONVERT(Bigint, MAX(Correlativo))+1,SUBSTRING(@cFhaOpe,9,2)+SUBSTRING(@cFhaOpe,4,2)+SUBSTRING(@cFhaOpe,1,2)+'0001') 
             FROM CTACTE WHERE IdEntCtaCte=@IdEntCtaCte AND FhaOpe=@FhaOpe AND LEN(Correlativo)=10
           --> Generacion Correlativo CtaCte Agente
		   IF @IdEntCtaCteAgt = '99'
		      SET @CorrelativoAgt=''
		   ELSE
		      BEGIN
		        SET @cFhaOpe=CONVERT(Char(10),@FhaOpe,103)
		        SELECT @CorrelativoAgt=ISNULL(CONVERT(Bigint, MAX(CorrelativoAgt))+1,SUBSTRING(@cFhaOpe,9,2)+SUBSTRING(@cFhaOpe,4,2)+SUBSTRING(@cFhaOpe,1,2)+'0001') 
                  FROM CTACTE WHERE IdEntCtaCteAgt=@IdEntCtaCteAgt AND FhaOpe=@FhaOpe AND LEN(CorrelativoAgt)=10
			  END
		   --> BLACKBOX
		   INSERT INTO BLACKBOX(FhaOpe,HoraOpe,IdUsuario,SerialPC,IpPublica,NroOpe,NroDocTri,IdAgeOrigen,IdAgeDestino,Tabla,Accion,Status,ImpGiro)
		      VALUES (@FhaOpe,@HoraOPe,@IdUsuGen,@SerialPC,@IpPublica,@NroOpe,@NroDocTri,@IdAgeOrigen,@IdAgeDestino,'MVTOGIRO','Generar Remesa','1',@ImpGiro)
           -->
		   IF SUBSTRING(@IdAgeDestino,1,2) IN ('54') OR @MxnUniteller='True' 
		      SET @ETCProm=@TCCAproxCob
		   ELSE
		      SET @ETCProm=0
           -->
		   IF SUBSTRING(@IdAgeDestino,1,2) IN ('54') 
		      INSERT INTO CTACTE(IdEntCtaCte,TipEmpresa,FhaOpe,DebHab,NroOpe,IdDocTri,NroDocTri,IdEntCtaCteAgt,Origen,Destino,Situacion,
			              SitCorresp,ImpGirRec,ImpComRec,ImpComRecAgt,ImpGirPag,ImpComPag,ImpComPagAgt,ImpUtilAgt,ImpUtilidad,Debe,Haber,
						  HaberCont,Saldo,DebeAgt,HaberAgt,SaldoAgt,FhaPago,FhaConciliacion,Status,StatusAgt,Switch,ImpGirPagAut,
						  EImpGirPag,EImpComPag,EImpComPagAgt,EImpUtilAgt,EImpUtilidad,EDebe,EHaber,ESaldo,ETCProm,
						  ETipCamb,ClaveGiro,Correlativo,CorrelativoAgt)
			      VALUES (@IdEntCtaCte,'C',@FhaOpe,'D',@NroOpe,@IdDocTri,@NroDocTri,@IdEntCtaCteAgt,@Origen,@Destino,@Situacion,
				          @SitCorresp,0,0,0,@EImpGiro,@EImpCorresp,@EImpAgente,@EImpUtilAgt,@EImpUtilidad,@Debe,0,
						  0,@Saldo,@DebeAgt,0,@SaldoAgt,'01-01-1900','01-01-1900','1','1','',@EImpGiro,
						  @ImpGiro,@ImpCorresp,@ImpAgente,@ImpUtilAgt,@ImpUtilidad,@ImpGiro+@ImpCorresp,0,@ESaldo,@ETCProm,
						  @TCCAproxCob,@ClaveGiro,@Correlativo,@CorrelativoAgt)
		   ELSE
		      INSERT INTO CTACTE(IdEntCtaCte,TipEmpresa,FhaOpe,DebHab,NroOpe,IdDocTri,NroDocTri,IdEntCtaCteAgt,Origen,Destino,Situacion,
			              SitCorresp,ImpGirRec,ImpComRec,ImpComRecAgt,ImpGirPag,ImpComPag,ImpComPagAgt,ImpUtilAgt,ImpUtilidad,Debe,Haber,
						  HaberCont,Saldo,DebeAgt,HaberAgt,SaldoAgt,FhaPago,FhaConciliacion,Status,StatusAgt,Switch,ImpGirPagAut,
						  EImpGirPag,EImpComPag,EImpComPagAgt,EImpUtilAgt,EImpUtilidad,EDebe,EHaber,ESaldo,ETCProm,
						  ETipCamb,ClaveGiro,Correlativo,CorrelativoAgt)
			      VALUES (@IdEntCtaCte,'C',@FhaOpe,'D',@NroOpe,@IdDocTri,@NroDocTri,@IdEntCtaCteAgt,@Origen,@Destino,@Situacion,
				          @SitCorresp,0,0,0,@ImpGiro,@ImpCorresp,@ImpAgente,@ImpUtilAgt,@ImpUtilidad,@Debe,0,
						  0,@Saldo,@DebeAgt,0,@SaldoAgt,'01-01-1900','01-01-1900','1','1','',@ImpGiro,
						  @EImpGiro,@EImpCorresp,@EImpAgente,@EImpUtilAgt,@EImpUtilidad,@EImpGiro+@EImpCorresp,0,@ESaldo,@ETCProm,
						  @TCCAproxCob,@ClaveGiro,@Correlativo,@CorrelativoAgt)
		   -->
		   IF @IdAgeOrigen IN ('12999','13999') --> Registrar Operacion CAJA ReEnvio Modulo y App Movil
		      BEGIN
			    --> Ingreso Dinero Total Pesos por la Remesa del Reenvio en Pesos Chilenos
		        SELECT @IdCaja=IdCaja,@Turno=Turno,@IdDivisa='CLP',@IdCajaDest='1000299' FROM CAJA WHERE IdUsuario=@IdUsuGen
                SELECT @ModuloSyst='C',@IdCliente='9999999',@NroFact=0,@FhaEmis='01-01-1900',@Exenta=0,@Afecto=0,@Iva=0,@Status='A'
				SELECT @IdCCostos=CASE WHEN @IdAgeOrigen='12999' THEN '46' ELSE '' END+CASE WHEN @IdAgeOrigen='13999' THEN '47' ELSE '' END
				SELECT @Glosa03='ASIENTO AUTOMATICO'
	            --> Obtener NroOpe de la 1era.Transaccion
				SELECT @NroOpeCja=NroOpeCja FROM PARAMETROS_CAB WHERE IdAgeOrigen=@IdAgeOrigen
	            UPDATE PARAMETROS_CAB SET NroOpeCja= NroOpeCja + 1 WHERE IdAgeOrigen=@IdAgeOrigen
		        -->
                SELECT @TipMvto='I',@CantIngr=@ImpTotalML,@CantEgre=0
				SELECT @Glosa01='COBRO AUTOMATICO GIRO => NRO.OPE: '+CONVERT(VARCHAR, @NroOpe)+'  '+@IdDocTri+': '+@NroDocTri
				SELECT @Glosa02='Imp.Giro: '+CONVERT(VARCHAR, FORMAT(@ImpGiro,'###,###.00 USD','es-PE'))+'   '+
				                'Comision: '+CONVERT(VARCHAR, FORMAT(@ImpTotal-@ImpGiro,'###,###.00 USD','es-PE'))+'   '+
				                'Total   : '+CONVERT(VARCHAR, FORMAT(@ImpTotal,'###,###.00 USD','es-PE'))+ '   '+
				                'Tip.Camb: '+CONVERT(VARCHAR, FORMAT(@TCVMEEnv,'###,###.00 CLP','es-PE'))
               --> 
	            INSERT INTO MVTOCAJA(IdCaja,Turno,IdUsuario,FhaOpe,NroOpe,HoraOpe,TipMvto,ModuloSyst,IdCCostos,IdDivisa,
				       IdCajaDest,CantIngr,CantEgre,Glosa01,Glosa02,Glosa03,IdCliente,NroFact,FhaEmis,Exenta,Afecto,Iva,Status)
		          VALUES (@IdCaja,@Turno,@IdUsuGen,@FhaOpe,@NroOpeCja,@HoraOpe,@TipMvto,@ModuloSyst,@IdCCostos,@IdDivisa,
                      @IdCajaDest,@CantIngr,@CantEgre,@Glosa01,@Glosa02,@Glosa03,@IdCliente,@NroFact,@FhaEmis,@Exenta,@Afecto,@Iva,@Status)
	            --> Obtener NroOpe de la 2da. Transaccion
				SELECT @NroOpeCja=NroOpeCja FROM PARAMETROS_CAB WHERE IdAgeOrigen=@IdAgeOrigen
	            UPDATE PARAMETROS_CAB SET NroOpeCja= NroOpeCja + 1 WHERE IdAgeOrigen=@IdAgeOrigen
		        -->
                SELECT @TipMvto='E',@CantIngr=0,@CantEgre=ROUND(@xImpGiroAnuUsd*@xTCVMEEnv,2),@Glosa01='PAGO AUTOMATICO '+@xMensaje
				IF @IdEntCtaCte='54' --> SOLES
    		       SELECT @Glosa02='Imp.Giro: '+CONVERT(VARCHAR, FORMAT(@xImpGiroAnuLoc,'###,###.00 PER','es-PE'))+'   => ('+
				                               +CONVERT(VARCHAR, FORMAT(@xImpGiroAnuUsd,'###,###.00 USD','es-PE'))+')    '+
				                   'Tip.Camb: '+CONVERT(VARCHAR, FORMAT(@TCVMEEnv,'###,###.00 CLP','es-PE'))
				ELSE                --> DOLARES 
    			   SELECT @Glosa02='Imp.Giro: '+CONVERT(VARCHAR, FORMAT(@xImpGiroAnuUsd,'###,###.00 USD','es-PE'))+'   '+
				                   'Tip.Camb: '+CONVERT(VARCHAR, FORMAT(@TCVMEEnv,'###,###.00 CLP','es-PE'))
                --> 
	            INSERT INTO MVTOCAJA(IdCaja,Turno,IdUsuario,FhaOpe,NroOpe,HoraOpe,TipMvto,ModuloSyst,IdCCostos,IdDivisa,
				       IdCajaDest,CantIngr,CantEgre,Glosa01,Glosa02,Glosa03,IdCliente,NroFact,FhaEmis,Exenta,Afecto,Iva,Status)
		          VALUES (@IdCaja,@Turno,@IdUsuGen,@FhaOpe,@NroOpeCja,@HoraOpe,@TipMvto,@ModuloSyst,@IdCCostos,@IdDivisa,
                      @IdCajaDest,@CantIngr,@CantEgre,@Glosa01,@Glosa02,@Glosa03,@IdCliente,@NroFact,@FhaEmis,@Exenta,@Afecto,@Iva,@Status)
			  END
		   -->
		   SELECT WNroOpe=@NroOpe,WIdDocTri=@IdDocTri,WNroDocTri=@NroDocTri,WSerDocTri=@SerDocTri,ClaveGiro=@ClaveGiro,WCostPromD=@CostPromD,WCostPromT=@CostPromT,WCostPromG=@CostPromG 
--		   SELECT @CostPromD=0,@CostPromT=0,@CostPromG=0
		 COMMIT  
	   END TRY 
	   BEGIN CATCH
		  ROLLBACK
	      INSERT INTO LOG_SYSTEM(Fecha,Hora,Modulo,Detalle,Observacion,IdUsuGen,Status)
            VALUES(CONVERT (char(10), getdate(), 103),SUBSTRING(CAST(SYSDATETIME() AS VARCHAR),12,8),
		           'PA_MVTOGIRO',ISNULL(ERROR_MESSAGE(),'NULL Error_Message'),
			       'Procedure: '+ISNULL(ERROR_PROCEDURE(),'NULL')+' en la Linea : '+CONVERT(VarChar,ISNULL(ERROR_LINE(),'NULL')),
			       '9999','1')
		  SELECT Error_Message(),WNroOpe=0
	   END CATCH
