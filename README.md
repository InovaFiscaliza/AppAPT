# AppAPT (Encerrado)

Projeto **AppColetaAPT** (submódulo do **AppColetaV2**).

Destina-se a ser um submódulo para automatizar as medições de parâmetros técnicos (APT), com estruturas para uma interface genérica que independa do instrumento usado. Entregar uma interface gráfica unificada, relatórios padronizados, e controle geral da instrumentação para que o fiscal concentre-se mais na análise do que na operação.

## Estrutura do projeto

- Cada instrumento herda todos os comandos comuns da classe abstrata Analysers (IEEE 488.2 Common Commands), mas possui em sua classe comandos específicos de seu fabricante e de seu modelo, o que torta a estrutura facilmente escalonável para quaisquer outros equipamentos que venhamos a adquirir, e para outras aplicações.
