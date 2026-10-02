/* =========================================================
   03 - Carga dos CSVs para o staging
   ---------------------------------------------------------
   Loop em todos os .csv da pasta configurada, carregando
   cada um via BULK INSERT dinâmico.

   ⚠️ LIÇÕES APRENDIDAS:
   - NÃO usar FORMAT='CSV' (conflita com FIELDTERMINATOR
     e ignora FIELDQUOTE, deixando aspas literais nos dados)
   - Usar CODEPAGE='1252' (Windows-1252 / Latin1, encoding
     original dos arquivos de transparência)
   - ROWTERMINATOR='0x0a' para arquivos com \n
   - TRY/CATCH por arquivo para não abortar o loop inteiro
     se um CSV estiver corrompido
   ========================================================= */

USE Transparencia;
GO

SET NOCOUNT ON;

-- 1. Limpa staging antes de recarregar
TRUNCATE TABLE dbo.stg_execucao;

-- 2. Configurar pasta dos CSVs
DECLARE @pasta NVARCHAR(260) = N'C:\Users\...\dados\';
SET @pasta = @pasta + CASE WHEN RIGHT(@pasta,1)='\' THEN '' ELSE '\' END;

-- 3. Listar arquivos
DECLARE @arquivos TABLE (arquivo NVARCHAR(260), profundidade INT, eh_arquivo INT);
INSERT INTO @arquivos EXEC master.sys.xp_dirtree @pasta, 1, 1;

-- 4. Loop
DECLARE @arquivo NVARCHAR(260), @sql NVARCHAR(MAX), @caminho NVARCHAR(520), @msg NVARCHAR(500);

DECLARE lista CURSOR LOCAL FAST_FORWARD FOR
    SELECT arquivo FROM @arquivos
    WHERE eh_arquivo = 1 AND arquivo LIKE '%.csv'
    ORDER BY arquivo;

OPEN lista;
FETCH NEXT FROM lista INTO @arquivo;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @caminho = @pasta + @arquivo;

    SET @sql = N'
        BULK INSERT dbo.stg_execucao
        FROM ' + QUOTENAME(@caminho, '''') + N'
        WITH (
            FIRSTROW        = 2,
            FIELDTERMINATOR = '';'',
            FIELDQUOTE      = ''"'',
            ROWTERMINATOR   = ''0x0a'',
            CODEPAGE        = ''1252'',
            TABLOCK
        );';

    BEGIN TRY
        EXEC sp_executesql @sql;
        SET @msg = N'OK   -> ' + @arquivo;
        PRINT @msg;
    END TRY
    BEGIN CATCH
        SET @msg = N'ERRO -> ' + @arquivo + N' | ' + ERROR_MESSAGE();
        PRINT @msg;
    END CATCH

    FETCH NEXT FROM lista INTO @arquivo;
END

CLOSE lista;
DEALLOCATE lista;

-- 5. Conferência
SELECT COUNT(*) AS linhas_carregadas FROM dbo.stg_execucao;
GO