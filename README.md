# AppAPT

Projeto **AppColetaAPT** (módulo do **AppColeta**).


O trabalho destina-se a automatizar as medições de APT. Está em **fase inicial**.

Neste primeiro passo, foram criadas estruturas para uma interface unificada de operação que independa do instrumento.

## Estrutura do projeto

- Na pasta Analysers está a superclasse Analyser, da qual todas as outras herdam os comandos básicos SCPI (Standard Commands for Programmable Instruments)/IEEE 488.2 Common Commands.
- Ao instrumento é solicitada sua identificação (IDN), que será utilizada para a carga dinâmica dos comandos dele.
- Caso o instrumento não tenha uma classe implementada, serão utilizados os comandos padrão do fabricante, e só será necessário criar o modelo caso haja funções ou parâmetros específicos para ele. 
- Nesta pasta estão os comandos comuns ao fabricante, trocando-se o & por _ nos casos como R&S e AT&T, para evitar caracteres estranhos que causam mal funcionamento nas chamadas dinâmicas.
- Caso um novo instrumento seja adquirido, basta acrescentar sua classe, o que torna o projeto escalonável, e facilita os testes individuais. 

## Testes

O TestTektronixSA2500.mlx é um live script para executar com um simulador SP2500PC (a URL para Download está em TestTektronixSA2500.mlx).
Os resultados estão em TestTektronixSA2500.pdf para referência rápida.

Futuramente, os testes serão movidos para uma pasta específica para validação das classes de instrumentos.
