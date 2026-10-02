USE Transparencia;
GO

-- 1. Limpa a tabela de apoio para recarregar tudo do zero
TRUNCATE TABLE dbo.stg_execucao;

-- 2. Lista os arquivos .csv da pasta
DECLARE @pasta NVARCHAR(260) = N'C:\Users\caina\OneDrive\data science\dados\';
DECLARE @arquivos TABLE (arquivo NVARCHAR(260), profundidade INT, eh_arquivo INT);
INSERT INTO @arquivos EXEC master.sys.xp_dirtree @pasta, 1, 1;

-- 3. Importa um arquivo por vez
DECLARE @arquivo NVARCHAR(260), @sql NVARCHAR(MAX);

DECLARE lista CURSOR LOCAL FAST_FORWARD FOR
    SELECT arquivo FROM @arquivos
    WHERE eh_arquivo = 1 AND arquivo LIKE '%.csv'
    ORDER BY arquivo;

OPEN lista;
FETCH NEXT FROM lista INTO @arquivo;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'BULK INSERT dbo.stg_execucao FROM ''' + @pasta + @arquivo + N''' '
             + N'WITH (FORMAT=''CSV'', FIELDTERMINATOR='';'', FIELDQUOTE=''"'', FIRSTROW=2, CODEPAGE=''1252'');';
    EXEC sp_executesql @sql;
    PRINT N'Importado: ' + @arquivo;
    FETCH NEXT FROM lista INTO @arquivo;
END

CLOSE lista;
DEALLOCATE lista;