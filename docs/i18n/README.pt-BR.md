# project-plan

[简体中文](../../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português (BR)](README.pt-BR.md)

Skill do Codex para manter o estado de um projeto entre sessões. Ele roda uma única vez, quando o projeto é criado: grava o `PLAN.md` e adiciona um bloco de regras ao `AGENTS.md` do repositório. As sessões seguintes seguem o `AGENTS.md` e o skill não é chamado novamente.

O `git log` registra o que mudou no código. O `PLAN.md` registra o objetivo, os motivos das decisões, a tarefa atual e os problemas já encontrados.

## Requisitos

- Codex com suporte a `AGENTS.md` (aplicativo desktop ou CLI)
- PowerShell 5.1 ou superior, apenas para os scripts
- Versão 0.2.0; veja `CHANGELOG.md`

## Instalação

```powershell
git clone https://github.com/LDPlong/project-plan.git
cd project-plan
powershell -File scripts/install.ps1
```

O destino padrão é `~/.codex/skills/project-plan`. Para instalar em outro local:

```powershell
powershell -File scripts/install.ps1 -Target D:\path\to\skills\project-plan
```

Também é possível copiar `skills/project-plan/` manualmente para o diretório de skills do Codex.

### Configuração manual (sem skill)

Se o skill não rodar, ou se você preferir não delegar ao agente, inicialize em três passos:

1. Copie `skills/project-plan/references/PLAN-template.md` para `PLAN.md` na raiz do projeto e preencha.
2. Acrescente `skills/project-plan/references/AGENTS-block.md` ao final do `AGENTS.md` do projeto; crie o arquivo se ele não existir.
3. Execute `powershell -File skills/project-plan/scripts/check-plan.ps1 -Path PLAN.md`.

## Uso

### 1. Inicializar um projeto

Abra a raiz do projeto no Codex e envie:

```text
Inicialize o plano do projeto com o skill project-plan.
```

O skill executa os passos abaixo:

1. Verifica se `PLAN.md` e o bloco de regras no `AGENTS.md` já existem. Se ambos existirem, ele para.
2. Confirma o objetivo, o critério de conclusão e o que está fora do escopo. Só pergunta quando não consegue deduzir da conversa.
3. Grava `PLAN.md` na raiz do projeto.
4. Grava `references/AGENTS-block.md` no bloco marcado do `AGENTS.md`, substituindo um bloco existente.
5. Executa o `scripts/check-plan.ps1` incluído contra o novo `PLAN.md`.

### 2. Trabalhar normalmente

No início da sessão, o Codex lê o `PLAN.md` e continua a partir do item em «进行中» (em andamento). Ao concluir uma tarefa, atualiza o plano e o inclui no mesmo commit do código. Não é necessário chamar o skill novamente.

### 3. Verificar o plano (opcional)

```powershell
powershell -File skills/project-plan/scripts/check-plan.ps1 -Path PLAN.md
```

Saída de exemplo:

```text
[OK] PLAN.md: 29/50 lines, in progress 1, todo 1, warnings 0
```

O script verifica o seguinte.

Falha (código de saída `1`):

- Falta uma seção obrigatória: 目标 / 非目标 / 进行中 / 待做 / 决策 / 坑
- Um título de seção aparece mais de uma vez
- 目标 está vazio ou ainda é um placeholder
- 进行中 tem duas ou mais tarefas não concluídas
- As linhas não vazias passam de 50

Avisos (o código de saída não muda):

- Falta 当前里程碑
- 进行中 não tem tarefas pendentes ou ainda contém `- [x]`
- 待做 ainda contém `- [x]`
- 目标 não contém "验收" nem "acceptance"
- Há uma tarefa em andamento e o arquivo não é alterado há 14 dias (`-MaxAgeDays 0` desativa)

"Linhas efetivas" significa linhas não vazias.

## Arquivos criados no projeto

| Arquivo | Conteúdo |
| --- | --- |
| `PLAN.md` | Objetivo, escopo, marco atual, tarefas, decisões, problemas |
| `AGENTS.md` | Conteúdo existente mais um bloco de regras marcado |

Os nomes das seções do `PLAN.md` são fixos em chinês. Não os traduza, pois o script de verificação e o bloco de regras deixariam de corresponder.

| Seção | Conteúdo |
| --- | --- |
| `## 目标` | Objetivo em uma frase, com o critério de conclusão |
| `## 非目标` | O que está explicitamente fora do escopo |
| `## 当前里程碑` | Nome do marco atual |
| `## 进行中` | No máximo uma tarefa |
| `## 待做` | Tarefas seguintes |
| `## 决策` | Data, decisão e motivo |
| `## 坑` | Sintoma, causa e solução |
| `## 归档` | Marcos concluídos, um por linha |

Exemplo:

```markdown
## 目标
Permitir login por e-mail; concluído quando um usuário novo consegue se cadastrar e entrar em menos de três minutos.

## 非目标
- Login por terceiros fica fora do escopo por enquanto

## 当前里程碑
M2 Autenticação de usuários

## 进行中
- [ ] T3 Endpoint de login (emissão e renovação de JWT)

## 待做
- [ ] T4 Redefinição de senha (depende do serviço de e-mail)

## 决策
- 2026-11-21 Usar JWT em vez de sessões: o deploy precisa ser sem estado

## 坑
- prisma migrate exige PostgreSQL local; sem ele retorna P1001

## 归档
- M1 Estrutura do projeto concluída (T1-T2, ver git log)
```

## Regras do plano

| Regra | Valor |
| --- | --- |
| Tamanho da tarefa | Um commit |
| Em andamento | No máximo um item na branch principal |
| Tamanho do arquivo | Até 50 linhas não vazias |
| Decisões | Com data e motivo |
| Tarefas concluídas | Uma linha de arquivo por marco |
| Acima do limite | Arquivar primeiro os marcos; depois mover decisões e problemas antigos para `docs/plan-archive.md` |
| Branches | Cada branch mantém seu próprio «进行中»; a branch principal reduz para um item no merge |
| Plano versus git | Fatos vêm do `git log`, intenção vem do `PLAN.md`; conflitos são confirmados manualmente |

## Estrutura do repositório

```text
skills/project-plan/SKILL.md                       Procedimento de inicialização
skills/project-plan/references/PLAN-template.md    Modelo do plano
skills/project-plan/references/AGENTS-block.md     Bloco de regras para AGENTS.md
skills/project-plan/scripts/check-plan.ps1         Verificação do plano (incluída no skill)
scripts/install.ps1                                Instalação e limpeza de arquivos removidos
scripts/verify-skill.ps1                           Autoteste do verificador (15 casos)
.github/workflows/plan-check.yml                   CI: verificação + aviso de plano desatualizado
CHANGELOG.md                                       Histórico de versões
```

## Perguntas frequentes

**O skill não foi executado.**
Skills são selecionados pela descrição. Cite o nome explicitamente: «Inicialize o plano do projeto com o skill project-plan». Se ainda assim não rodar, use a configuração manual acima.

**Uma sessão nova não lê o PLAN.md.**
Confirme que o Codex inicia na raiz do projeto ou em um subdiretório e que o `AGENTS.md` contém o bloco entre `<!-- project-plan:begin -->` e `<!-- project-plan:end -->`. Também é possível adicionar uma linha de fallback em `~/.codex/AGENTS.md`:

```markdown
- Se existir `PLAN.md` no diretório de trabalho ou em qualquer diretório pai, leia as seções 目标 / 进行中 / 决策 / 坑 antes de iniciar uma tarefa; caso contrário, ignore esta regra.
```

**O projeto já tem um AGENTS.md. Haverá conflito?**
Não. O bloco é adicionado ao final do arquivo e o restante permanece intacto. Ao executar novamente, apenas o conteúdo entre os marcadores é substituído.

**Onde o PLAN.md deve ficar?**
Na raiz do projeto. Um arquivo por repositório. Não use um local global.

**O PLAN.md deve ser commitado?**
Sim. Ele faz parte do estado do projeto e deve ser revisado como o código. Em um repositório público, o plano também passa a fazer parte do histórico público; se isso não for aceitável, use um repositório privado ou adicione `PLAN.md` ao `.gitignore` (nesse caso o estado entre sessões existe apenas localmente).

**Vários projetos podem compartilhar um plano?**
Não. Cada raiz de projeto tem o seu próprio arquivo.

## Desinstalação

1. Exclua `~/.codex/skills/project-plan`.
2. Remova o bloco entre os dois marcadores no `AGENTS.md`.
3. Exclua o `PLAN.md` se ele não for mais necessário.

## Licença

MIT