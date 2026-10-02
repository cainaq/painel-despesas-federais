/* =========================================================
   01 - Criação do banco de dados
   ---------------------------------------------------------
   Cria o banco 'Transparencia' que vai hospedar todas as
   tabelas e views do projeto.
   ========================================================= */

IF DB_ID('Transparencia') IS NULL
BEGIN
    CREATE DATABASE Transparencia;
    PRINT 'Banco Transparencia criado.';
END
ELSE
BEGIN
    PRINT 'Banco Transparencia já existe.';
END
GO

USE Transparencia;
GO