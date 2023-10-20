# AppAPT

Projeto **AppColetaAPT** (módulo do **AppColeta**).


O trabalho destina-se a automatizar as medições de parâmetros técnicos (APT). Está em **fase inicial**.

Neste primeiro passo, foram criadas estruturas para uma interface unificada de operação que independa do instrumento.

## Estrutura do projeto

- Na pasta Analysers está a superclasse +Analyser, da qual todas as outras herdam os comandos básicos SCPI (Standard Commands for Programmable Instruments)/IEEE 488.2 Common Commands.
- Ao instrumento é solicitada sua identificação (IDN), que será utilizada para a carga dinâmica dos comandos dele.
- Caso o instrumento não tenha uma classe implementada, serão utilizados os comandos padrão do fabricante, e só será necessário criar o modelo caso haja funções ou parâmetros específicos para ele, como por exemplo a _scpiReset_ em _SA2500PC_, sobrecarregada porque o comando real encerra o simulador, mas que o instrumento real não vai herdar por possuir uma identificação diferente (sem sufixo PC).
- Na pasta +Analysers estão os comandos comuns ao fabricante, trocando-se o & por _ nos casos como R&S e AT&T para R\_S e AT\_T, para evitar caracteres que causam mau funcionamento nas chamadas dinâmicas.
- Caso um novo instrumento seja adquirido, basta acrescentar sua classe, o que torna o projeto escalonável, e facilita os testes individuais.
- Os método _connTCP_ é estáticos porque o objeto ainda não foi criado por _instance_ e reinicia a conexão ao terminar, utilizada a nomenclatura _anl_ para esta situação. Os demais casos reutilizam a conexão já existente, armazenada no _handler_ _conn_ da superclasse _Analyser_.

## Testes

Em Analyers/TestBook estão os livros de testes dos instrumentos. Os resultados estão em pdf para referência rápida.

As funções em +fcn comporão uma classe estática para absorvê-las quando prontas.

