# randol_cargo — Manual

Entregas de carga inspiradas no GTA Online: pegue um flatbed ou duneloader com o NPC transportador, leve o engradado até o ponto sorteado e volte para receber.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Rotas e pagamento](#rotas-e-pagamento)
5. [Fluxo da entrega](#fluxo-da-entrega)
6. [Bridge de framework](#bridge-de-framework)
7. [Integrações](#integrações)
8. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
9. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `ox_lib` | Sim | Callbacks, `lib.points`, zonas, Text UI, menu de contexto, scaleform |
| Framework (`qb-core`, `ox_core`, `es_extended` ou `ND_Core`) | Sim | Um deles. A bridge detecta automaticamente qual está rodando |
| `cw-rep` | Sim | O pagamento chama `exports['cw-rep']:updateSkill(source, 'cargo', 5)` sem checagem — sem o recurso, a entrega falha ao pagar |
| `rep-talkNPC` | Não | Necessário quando `talkNPC = true` (padrão). Cria o NPC com diálogo |
| `qb-target` | Não | Necessário quando `talkNPC = false` e `Target = true` |
| `cdn-fuel` (ou outro script de combustível) | Não | Usado quando `Fuel.enable = true`, via `exports[Fuel.script]:SetFuel` |

---

## Instalação

1. Copie a pasta `randol_cargo` para `resources/`.
2. Adicione ao `server.cfg`:
   ```
   ensure randol_cargo
   ```
3. Escolha o modo de interação em `config.lua`: `talkNPC` (padrão), `Target` ou zona com tecla `E`.
4. Ajuste `Fuel` conforme o script de combustível do servidor (ou desligue para usar o statebag `fuel`).
5. Preencha `handleVehicleKeys` no arquivo de bridge do seu framework (`bridge/client/<framework>.lua`) se o seu sistema de chaves não for o `vehiclekeys:client:SetOwner`.

---

## Configuração

Arquivo: `config.lua`.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `Debug` | bool | Não | Flag de depuração |
| `Fuel.enable` | bool | Sim | `true` chama `exports[Fuel.script]:SetFuel(veh, 100.0)`. `false` define `Entity(veh).state.fuel = 100` (para `ox_fuel` e similares) |
| `Fuel.script` | string | Sim | Nome do recurso de combustível. Padrão: `cdn-fuel` |
| `Ped` | string | Sim | Modelo do NPC transportador. Padrão: `mp_m_weapexp_01` |
| `PedCoords` | vec4 | Sim | Posição e heading do NPC. Também é onde fica o blip do trabalho |
| `VehicleSpawn` | vec4 | Sim | Vaga onde o caminhão é spawnado. Bloqueada se houver outro veículo a menos de 5 m |
| `SpawnInVeh` | bool | Sim | `true` teleporta o jogador direto para o banco do motorista |
| `DeliveryInfo` | tabela | Sim | Scaleform exibido ao aceitar a entrega: `title`, `msg`, `sec` (duração), `audioName`, `audioRef` |
| `ReturnInfo` | tabela | Sim | Scaleform exibido ao entregar a carga, avisando para voltar e receber. Mesmos campos |
| `talkNPC` | bool | Sim | `true` usa `rep-talkNPC` com diálogo e **ignora as opções abaixo** |
| `Target` | bool | Sim | Só vale com `talkNPC = false`. `true` usa `qb-target` no ped; `false` usa zona `ox_lib` com tecla `E` |

---

## Rotas e pagamento

Arquivo: `sv_routes.lua`. É uma lista de tipos de entrega; a cada trabalho, uma entrada é sorteada, e dentro dela um dos `routes` é sorteado como destino.

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `vehicle` | string | Sim | Spawn name do caminhão (`flatbed`, `dloader`) |
| `prop` | string | Sim | Modelo do engradado preso na carroceria |
| `routes` | array de vec3 | Sim | Possíveis pontos de entrega. Um é sorteado por trabalho |
| `attach` | vec3 | Sim | Offset de fixação do engradado no bone `bodyshell` do veículo |
| `payout.min` / `payout.max` | number | Sim | Faixa de pagamento. O valor é sorteado no início do trabalho e pago em dinheiro |

As duas rotas padrão:

| Veículo | Pontos de entrega | Pagamento |
|---|---|---|
| `flatbed` | 7 | R$ 2.500 a R$ 3.700 |
| `dloader` | 8 | R$ 2.100 a R$ 3.200 |

---

## Fluxo da entrega

1. O blip "Transportador" marca o NPC no mapa. O ped só é criado quando o jogador chega a 30 m.
2. Interagindo com o NPC, o servidor sorteia a rota, spawna o caminhão em `VehicleSpawn` com o engradado já preso, e entrega as chaves (placa `CARG` + 4 dígitos, tanque cheio, extras 2 e 3 ligados).
3. Um scaleform (`DeliveryInfo`) anuncia a missão e o ponto de entrega ganha blip com rota.
4. No destino, um marcador azul é desenhado. Com o caminhão carregado e a menos de 4 m do ponto, `E` inicia a descarga (barra de 5 s).
5. O servidor valida que o jogador está a menos de 15 m do destino, deleta o engradado e marca a rota como concluída. O scaleform `ReturnInfo` manda voltar ao armazém.
6. De volta ao NPC, "Finalizar a entrega" paga o valor sorteado em dinheiro, adiciona 5 pontos de skill `cargo` no `cw-rep` e deleta o caminhão.

Finalizar sem ter descarregado a carga **não paga nada**: o engradado e o caminhão são deletados e o trabalho é encerrado. Se o jogador cair do servidor no meio da entrega, o caminhão e o engradado são deletados automaticamente.

---

## Bridge de framework

Cada arquivo em `bridge/` só é carregado se o recurso correspondente estiver `started`:

| Framework | Arquivo | Detecção |
|---|---|---|
| QBCore | `bridge/client/qb.lua`, `bridge/server/qb.lua` | `qb-core` |
| ox_core | `bridge/client/ox.lua`, `bridge/server/ox.lua` | `ox_core` |
| ESX | `bridge/client/esx.lua`, `bridge/server/esx.lua` | `es_extended` |
| ND | `bridge/client/nd.lua`, `bridge/server/nd.lua` | `ND_Core` |

As funções que a bridge precisa fornecer:

- `GetPlayer(id)` / `AddMoney(Player, type, amount)` / `DoNotification(...)` — servidor.
- `handleVehicleKeys(veh)` / `hasPlyLoaded()` / `DoNotification(text, type)` — cliente.
- `OnPlayerLoaded()` / `OnPlayerUnload()` — chamadas nos eventos de login/logout do framework.

O `handleVehicleKeys` no bridge do QBCore usa `vehiclekeys:client:SetOwner`. Nos bridges do `ox_core` e do ESX ele vem vazio, para o servidor preencher com seu sistema de chaves.

---

## Integrações

### rep-talkNPC

Com `talkNPC = true` (padrão), o NPC é criado por `exports['rep-talkNPC']:CreateNPC` com diálogo em português ("Seu Zé", tag TRANSPORTADOR). As opções de diálogo iniciam ou finalizam a entrega. Esse modo sobrepõe o `Target` e a zona `E`.

### cw-rep

Ao concluir a entrega, o recurso chama `exports['cw-rep']:updateSkill(source, 'cargo', 5)`. A chamada não é condicional — o `cw-rep` precisa estar rodando.

### Combustível

Com `Fuel.enable = true`, o caminhão spawna com `exports[Config.Fuel.script]:SetFuel(veh, 100.0)`. Com `false`, o recurso apenas define `Entity(veh).state.fuel = 100`, que é o formato usado pelo `ox_fuel`.

---

## Entrypoints para outros recursos

Não há exports. Callbacks registrados no servidor:

```lua
-- Sorteia rota, spawna caminhão + engradado e inicia o trabalho
lib.callback.await('randol_cargo:server:beginRoute', false)

-- Valida a distância do destino (15 m) e conclui a rota. Recebe o netId do engradado
lib.callback.await('randol_cargo:server:updateRoute', false, crateNetId)

-- Paga (se a rota foi concluída) e deleta o caminhão
lib.callback.await('randol_cargo:server:finishRoute', false)
```

Evento de cliente disparado pelo servidor ao iniciar o trabalho (ignora chamadas vindas de outros recursos):

```lua
TriggerClientEvent('randol_cargo:client:startRoute', src, routeData, vehicleNetId, crateNetId)
```

---

## Estrutura de arquivos

```
randol_cargo/
├── cl_cargo.lua          — NPC, blips, scaleforms, ponto de entrega, descarga
├── sv_cargo.lua          — sorteio da rota, spawn do caminhão e engradado, validação e pagamento
├── sv_routes.lua         — tabela de rotas: veículo, prop, destinos, offset e faixa de pagamento
├── config.lua            — NPC, vaga de spawn, combustível, modo de interação, scaleforms
├── bridge/
│   ├── client/
│   │   ├── qb.lua        — QBCore: login/logout, chaves, notificações
│   │   ├── ox.lua        — ox_core
│   │   ├── esx.lua       — ESX
│   │   └── nd.lua        — ND
│   └── server/
│       ├── qb.lua        — QBCore: GetPlayer, AddMoney, notificações
│       ├── ox.lua        — ox_core
│       ├── esx.lua       — ESX
│       └── nd.lua        — ND
└── fxmanifest.lua
```
