       
-- | Listar detalhes de pedidos com descontos definido pelo USUÁRIO |
SELECT *
FROM VisaoDetalhesPedido
WHERE PorcentagemDesconto > $1;

-- | Numero de vendas por Categoria |
SELECT Categoria, SUM(Quantidade) AS TotalVendas
FROM VisaoDetalhesPedido
GROUP BY Categoria;

-- | Produtos com nota acima de parametro passado pelo USUÁRIO |
SELECT 
    p.nome AS NomeProduto,
AVG(CAST(ap.Nota AS FLOAT)) AS MediaAvaliacao
FROM Produto p
JOIN AvaliaProduto ap ON p.codigo = ap.CodigoProduto
GROUP BY p.nome
HAVING AVG(CAST(ap.Nota AS FLOAT)) > $1;
    

-- | Produtos de pedidos que não foram avaliados - uteis para enviar email ao cliente pedido para fazer a avaliação |
SELECT 
    DISTINCT c.CodigoProduto,
    prod.nome AS NomeProduto,
    cli.email as EmailCliente,
    p.datapedido as DataPedido
FROM Pedido p
JOIN CompoeCarrinho c ON p.CodigoCarrinho = c.CodigoCarrinho
JOIN Produto prod ON c.CodigoProduto = prod.codigo
JOIN Cliente cli ON c.CodigoCliente = cli.email
WHERE NOT EXISTS (
        SELECT 1
        FROM AvaliaProduto ap
        WHERE ap.CodigoProduto = c.CodigoProduto
            	AND ap.CodigoCliente = c.CodigoCliente
    );
    
   
-- | Produtos que nunca foram comprados |
SELECT 
    p.codigo AS CodigoProduto,
    p.nome AS NomeProduto
FROM Produto p
WHERE NOT EXISTS (
        SELECT 1
        FROM CompoeCarrinho cc
        WHERE cc.CodigoProduto = p.codigo
    );

-- | Identificar o cliente que mais gastou em uma unica transação |
SELECT 
    cc.CodigoCliente,
    cli.nome AS NomeCliente,
    COUNT(DISTINCT cc.CodigoCarrinho) AS TotalTransacoes
FROM CompoeCarrinho cc
JOIN Cliente cli ON cc.CodigoCliente = cli.email
GROUP BY cc.CodigoCliente, cli.nome
ORDER BY TotalTransacoes DESC
LIMIT 1;

-- | Produtos com um estoque abaixo de uma quantidade unidades definida pelo USUÁRIO util para saber quais reabastecer |
SELECT 
    codigo AS CodigoProduto,
    nome AS NomeProduto,
    estoque AS EstoqueAtual
FROM Produto
WHERE estoque < $1;
   
   
-- | Categoria com maior número de vendas |
SELECT 
    c.CodigoCategoria,
    cat.nome AS NomeCategoria,
    COUNT(*) AS TotalVendido
FROM Categoriza c
JOIN CompoeCarrinho cc ON c.CodigoProduto = cc.CodigoProduto
join Categoria cat ON c.CodigoCategoria = cat.codigo
GROUP BY  c.CodigoCategoria, cat.nome
ORDER BY TotalVendido DESC
LIMIT 1;

-- | Clientes que possuem itens favoritados em promoção |
SELECT 
    DISTINCT cli.email AS EmailCliente,
    cli.nome AS NomeCliente,
    p.codigo AS CodigoProduto,
    p.nome AS NomeProduto,
    p.preco AS ValorProduto,
    prom.desconto AS ValorDesconto
FROM Cliente cli
join CompoeFavorito cf ON cli.email = cf.CodigoUsuario
JOIN Produto p ON cf.CodigoProduto = p.codigo
JOIN Categoriza c ON p.codigo = c.CodigoProduto
JOIN Promocao prom ON c.CodigoCategoria = prom.CodigoCategoria
WHERE prom.dataInicio <= CURRENT_DATE AND prom.dataFim >= CURRENT_DATE;

-- | GATILHO - Tenta inserir no carrinho uma quantidade X do produto 8 (SSD NVME 1TB) |
INSERT INTO CompoeCarrinho (CodigoCarrinho, CodigoCliente, CodigoProduto, Quantidade)
values
  (1, 'joaosilva@email.com', 8, $1);