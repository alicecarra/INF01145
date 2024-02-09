-- CRIAÇÃO DE TABELAS

-- Tabela Cliente
CREATE TABLE Cliente (
    email VARCHAR(255) PRIMARY KEY,
    cpf BIGINT UNIQUE,
    nome VARCHAR(255) NOT NULL,
    dataNascimento DATE NOT NULL,
    telefone BIGINT NOT NULL,
    senha VARCHAR(255) NOT NULL
);

-- Tabela Endereco
CREATE TABLE Endereco (
    identificador VARCHAR(255),
    uf VARCHAR(2) NOT NULL,
    cep BIGINT NOT NULL,
    cidade VARCHAR(255) NOT NULL,
    rua VARCHAR(255) NOT NULL,
    numero INT NOT NULL,
    complemento VARCHAR(255),
    email_cliente VARCHAR(255) REFERENCES Cliente(email),
    primary key (identificador, email_cliente)
);

-- Tabela Produto
CREATE TABLE Produto (
    codigo SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    descricao TEXT NOT NULL,
    marca TEXT NOT NULL,
    imagem VARCHAR(255) NOT NULL,
    peso FLOAT,
    preco FLOAT NOT NULL,
    estoque FLOAT NOT NULL
);

-- Tabela Categoria
CREATE TABLE Categoria (
    codigo VARCHAR(255) PRIMARY KEY,
    nome VARCHAR(255) NOT NULL
);

-- Tabela Categoriza
CREATE TABLE Categoriza (
    CodigoProduto SERIAL REFERENCES Produto(codigo),
    CodigoCategoria VARCHAR(255) REFERENCES Categoria(codigo),
    PRIMARY KEY (CodigoProduto, CodigoCategoria)
);


-- Tabela Promocao
CREATE TABLE Promocao (
    codigo VARCHAR(255) PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    dataInicio DATE NOT NULL,
    dataFim DATE NOT NULL,
    desconto FLOAT NOT NULL,
    codigoCategoria VARCHAR(255) NOT NULL REFERENCES Categoria(codigo)
);

-- Tabela EfetuaPagamento
CREATE TABLE EfetuaPagamento (
    CodigoCliente VARCHAR(255) PRIMARY KEY REFERENCES Cliente(email),
    CodigoPagamento SERIAL
);

-- Tabela MetodoPagamento
CREATE TABLE MetodoPagamento (
    CodigoPagamento SERIAL PRIMARY KEY,
    DataConfirmacao DATE
);

-- Tabela Cartao
CREATE TABLE Cartao (
    NumeroCartao VARCHAR(255) PRIMARY KEY,
    NomeTitular VARCHAR(255) NOT NULL,
    CPFTitular BIGINT NOT NULL,
    ValidadeCartao DATE NOT NULL,
    CVV INT NOT NULL,
    CodigoPagamento SERIAL REFERENCES MetodoPagamento(CodigoPagamento)
);

-- Tabela Pix
CREATE TABLE Pix (
    CodigoPix VARCHAR(255) PRIMARY KEY,
    Expiracao DATE NOT NULL,
    CodigoPagamento SERIAL REFERENCES MetodoPagamento(CodigoPagamento)
);

-- Tabela Boleto
CREATE TABLE Boleto (
    CodigoBoleto VARCHAR(255) PRIMARY KEY,
    Vencimento DATE NOT NULL,
    CodigoPagamento SERIAL REFERENCES MetodoPagamento(CodigoPagamento)
);


-- Tabela Carrinho
CREATE TABLE Carrinho (
  CodigoCarrinho SERIAL PRIMARY KEY,
  DataCriação DATE NOT NULL
);


-- Tabela CompoeCarrinho
CREATE TABLE CompoeCarrinho (
    CodigoCarrinho SERIAL REFERENCES Carrinho(CodigoCarrinho),
    CodigoCliente VARCHAR(255) REFERENCES Cliente(email),
    CodigoProduto SERIAL REFERENCES Produto(codigo),
    Quantidade INT NOT null,
  PRIMARY KEY (CodigoCliente, CodigoProduto, CodigoCarrinho)
);


-- Tabela Pedido
CREATE TABLE Pedido (
    CodigoPedido VARCHAR(255) PRIMARY KEY,
    CodigoCarrinho SERIAL REFERENCES Carrinho(CodigoCarrinho),
    DataPedido DATE NOT NULL,
    CodigoPagamento SERIAL REFERENCES MetodoPagamento(CodigoPagamento),
    TotalPedido FLOAT NOT NULL
);

-- Tabela Transportadora
CREATE TABLE Transportadora (
    CodigoTransportadora SERIAL PRIMARY KEY,
    NomeTransportadora VARCHAR(255) NOT NULL,
    TelefoneTransportadora BIGINT NOT NULL,
    EnderecoTransportadora VARCHAR(255) NOT NULL
);


-- Tabela AvaliaProduto
CREATE TABLE AvaliaProduto (
    CodigoCliente VARCHAR(255) REFERENCES Cliente(email),
    CodigoProduto SERIAL REFERENCES Produto(codigo),
    Data DATE NOT NULL,
    Nota INT CHECK (Nota >= 1 AND Nota <= 5) NOT NULL,
    Comentario TEXT,
    PRIMARY KEY (CodigoCliente, CodigoProduto)
);


-- Tabela CompoeFavorito
CREATE TABLE CompoeFavorito (
    CodigoUsuario VARCHAR(255) REFERENCES Cliente(email),
    CodigoProduto SERIAL REFERENCES Produto(codigo),
    PRIMARY KEY (CodigoUsuario, CodigoProduto)
);

-- Tabela EnvioPedido
CREATE TABLE EnvioPedido (
    CodigoPedido VARCHAR(255) REFERENCES Pedido(CodigoPedido),
    CodigoTransportadora SERIAL REFERENCES Transportadora(CodigoTransportadora),
    Data DATE NOT NULL,
    ValorFrete FLOAT NOT NULL,
    PRIMARY KEY (CodigoPedido, CodigoTransportadora)
);


-- Criar a visão que relaciona Pedido, Cliente e Produto com possível desconto de Promoção.
CREATE VIEW VisaoDetalhesPedido AS
select 
    ped.CodigoPedido,
    ped.DataPedido,
    cli.email AS EmailCliente,
    prod.nome AS NomeProduto,
    cat.nome as Categoria,
    c.Quantidade,
    c.Quantidade * prod.preco AS Subtotal,
    COALESCE(prom.desconto, 0) AS PorcentagemDesconto -- 
FROM Pedido ped
JOIN Carrinho ccp ON ped.CodigoCarrinho = ccp.CodigoCarrinho
join compoecarrinho c on ccp.codigocarrinho = c.codigocarrinho 
JOIN Cliente cli ON c .CodigoCliente = cli.email
JOIN Produto prod ON c.CodigoProduto = prod.codigo
JOIN Categoriza categoriza ON prod.codigo = categoriza.CodigoProduto
JOIN Categoria cat ON cat.codigo = categoriza.CodigoCategoria
LEFT JOIN Promocao prom ON cat.codigo = prom.codigocategoria
                     AND ped.DataPedido BETWEEN prom.dataInicio AND prom.dataFim;
                     
            
-- GATILHO/FUNC. ARMAZ.

-- Função armazenada para verificar o estoque disponível de um produto
CREATE OR REPLACE FUNCTION verificaEstoqueDisponivel(codigo_produto INT, quantidade INT) RETURNS BOOLEAN AS $$
DECLARE
    estoque_disponivel FLOAT;
BEGIN
    -- Obtém o estoque disponível para o produto especificado
    SELECT estoque INTO estoque_disponivel FROM Produto WHERE codigo = codigo_produto;
    -- Verifica se há estoque suficiente para a quantidade desejada
    IF estoque_disponivel >= quantidade THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Gatilho para verificar estoque antes da inserção no carrinho
CREATE OR REPLACE FUNCTION verificaEstoqueTrigger() RETURNS TRIGGER AS $$
BEGIN
    IF NOT verificaEstoqueDisponivel(NEW.CodigoProduto, NEW.Quantidade) THEN
            -- Se não houver estoque suficiente, lança uma exceção
        RAISE EXCEPTION 'Estoque insuficiente para adicionar o produto ao carrinho';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verificaEstoqueBeforeInsert BEFORE INSERT ON CompoeCarrinho
FOR EACH ROW EXECUTE FUNCTION verificaEstoqueTrigger();


-- INSERÇÕES

-- Inserção de dados na tabela Cliente
INSERT INTO Cliente (email, cpf, nome, dataNascimento, telefone, senha)
VALUES
  ('joaosilva@email.com', 12345678901, 'João Silva', '1990-05-15', 1122334455, 'senha123'),
  ('mariaoliveira@email.com', 98765432109, 'Maria Oliveira', '1985-08-22', 9988776655, 'senha456');

-- Inserção de dados na tabela Endereco
INSERT INTO Endereco (identificador, uf, cep, cidade, rua, numero, complemento, email_cliente)
VALUES
  ('endereco1', 'SP', 12345678, 'São Paulo', 'Rua A', 123, 'Apto 456', 'joaosilva@email.com'),
  ('endereco2', 'RJ', 87654321, 'Rio de Janeiro', 'Rua B', 456, 'Casa 789', 'mariaoliveira@email.com');

-- Inserção de dados na tabela Produto
INSERT INTO Produto (codigo, nome, descricao, marca, imagem, peso, preco, estoque)
values
  (8, 'SSD NVME 1TB', 'Armazenamento Flash mais rápido do mercado', 'Crucial', 'imagem38.jpg', 0.3, 399.99, 2),
  (1, 'Processador Core i9-9900K', 'Processador para alto desempenho', 'Intel', 'imagem3.jpg', 0.3, 1200.00, 15),
  (2, 'Memória RAM 16GB DDR4', 'Módulo de memória para upgrade', 'Corsair', 'imagem4.jpg', 0.1, 150.00, 30),
  (3, 'Placa-Mãe ASUS ROG Strix Z390', 'Placa-mãe para entusiastas', 'ASUS', 'imagem5.jpg', 1.0, 400.00, 10),
  (4, 'Teclado Mecânico RGB', 'Teclado mecânico para gamers', 'Logitech', 'imagem6.jpg', 1.2, 200.00, 25),
  (5, 'Mouse Óptico Gamer', 'Mouse óptico com alta precisão', 'Razer', 'imagem7.jpg', 0.2, 80.00, 50),
  (6, 'HD Externo 1TB', 'Armazenamento externo portátil', 'Western Digital', 'imagem8.jpg', 0.5, 250.00, 15),
  (7, 'Monitor LED 24"', 'Monitor widescreen para computadores', 'Samsung', 'imagem9.jpg', 3.0, 400.00, 20);

-- Inserção de dados na tabela Categoria
INSERT INTO Categoria (codigo, nome)
VALUES
  ('processador', 'Processadores'),
  ('memoria', 'Memórias RAM'),
  ('placa_mae', 'Placas-Mãe'),
  ('periferico', 'Periféricos'),
  ('armazenamento', 'Armazenamento');


-- Inserção de dados na tabela Promocao
INSERT INTO Promocao (codigo, nome, dataInicio, dataFim, desconto, codigoCategoria)
values
  ('promo0', 'Tem espaço pra tudo!', '2024-01-01', '2024-02-21', 0.10, 'armazenamento'),
  ('promo1', 'Desconto Placas Mães', '2024-02-01', '2024-02-15', 0.10, 'placa_mae'),
  ('promo2', 'Oferta RAM', '2024-03-01', '2024-03-15', 0.15, 'memoria');

-- Inserção de dados na tabela EfetuaPagamento
INSERT INTO EfetuaPagamento (CodigoCliente)
VALUES
  ('joaosilva@email.com'),
  ('mariaoliveira@email.com');

-- Inserção de dados na tabela MetodoPagamento
INSERT INTO MetodoPagamento (CodigoPagamento, DataConfirmacao)
VALUES
  (1, '2024-02-10'),
  (2, '2024-02-12');

-- Inserção de dados na tabela Cartao
INSERT INTO Cartao (NumeroCartao, NomeTitular, CPFTitular, ValidadeCartao, CVV, CodigoPagamento)
VALUES
  ('1234567890123456', 'João Silva', 12345678901, '2025-12-01', 123, 1),
  ('9876543210987654', 'Maria Oliveira', 98765432109, '2026-10-01', 456, 2);

-- Inserção de dados na tabela Pix
INSERT INTO Pix (CodigoPix, Expiracao, CodigoPagamento)
VALUES
  ('pix123', '2024-02-20', 1),
  ('pix456', '2024-02-22', 2);

-- Inserção de dados na tabela Boleto
INSERT INTO Boleto (CodigoBoleto, Vencimento, CodigoPagamento)
VALUES
  ('boleto1', '2024-02-25', 1),
  ('boleto2', '2024-02-28', 2);

-- Inserção de dados na tabela Carrinho
INSERT INTO Carrinho (CodigoCarrinho, DataCriação)
VALUES
  (1, '2024-02-01'),
  (2, '2024-02-03');

-- Inserção de dados na tabela CompoeCarrinho
INSERT INTO CompoeCarrinho (CodigoCarrinho, CodigoCliente, CodigoProduto, Quantidade)
values
  (1, 'joaosilva@email.com', 2, 4),
  (1, 'joaosilva@email.com', 3, 1),
  (1, 'joaosilva@email.com', 1, 1),
  (2, 'mariaoliveira@email.com', 2, 1);

-- Inserção de dados na tabela Pedido
INSERT INTO Pedido (CodigoPedido, CodigoCarrinho, DataPedido, CodigoPagamento, TotalPedido)
VALUES
  ('pedido1', 1, '2024-02-10', 1, 3000.00),
  ('pedido2', 2, '2024-02-12', 2, 600.00);

-- Inserção de dados na tabela Transportadora
INSERT INTO Transportadora (codigotransportadora, NomeTransportadora, TelefoneTransportadora, EnderecoTransportadora)
VALUES
  (1, 'Transportadora Rápida', 1122334455, 'Rua Transporte, 123');
 
 
-- Inserção de dados na tabela AvaliaProduto
INSERT INTO AvaliaProduto (CodigoCliente, CodigoProduto, Data, Nota, Comentario)
VALUES
  ('joaosilva@email.com', 1, '2024-02-15', 4, 'Ótimo produto! Recomendo.'),
  ('mariaoliveira@email.com', 2, '2024-02-18', 5, 'Excelente SSD, velocidade incrível.');

-- Inserção de dados na tabela CompoeFavorito
INSERT INTO CompoeFavorito (CodigoUsuario, CodigoProduto)
values
  ('joaosilva@email.com', 6),
  ('joaosilva@email.com', 1),
  ('mariaoliveira@email.com', 2);

-- Inserção de dados na tabela Categoriza
INSERT INTO Categoriza (CodigoProduto, CodigoCategoria)
VALUES
  (1, 'processador'),
  (2, 'memoria'),
  (3, 'placa_mae'),
  (4, 'periferico'),
  (5, 'periferico'),
  (6, 'armazenamento'),
  (7, 'periferico');
 
-- Inserção de dados na tabela EnvioPedido
INSERT INTO EnvioPedido (CodigoPedido, CodigoTransportadora, Data, ValorFrete)
VALUES
  ('pedido1', 1, '2024-02-12', 50.00),
  ('pedido2', 1, '2024-02-15', 30.00);
