# project-plan

[简体中文](../../README.md) · [English](README.en.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Português (BR)](README.pt-BR.md)

Skill de Codex para conservar el estado de un proyecto entre sesiones. Se ejecuta una sola vez, al crear el proyecto: genera `PLAN.md` y añade un bloque de reglas al `AGENTS.md` del repositorio. Las sesiones siguientes siguen `AGENTS.md`; el skill no se vuelve a invocar.

`git log` registra los cambios del código. `PLAN.md` registra el objetivo, los motivos de las decisiones, la tarea actual y los problemas ya encontrados.

## Requisitos

- Codex con soporte de `AGENTS.md` (aplicación de escritorio o CLI)
- PowerShell 5.1 o superior, solo para los scripts
- Versión 0.2.0; consulta `CHANGELOG.md`

## Instalación

```powershell
git clone https://github.com/LDPlong/project-plan.git
cd project-plan
powershell -File scripts/install.ps1
```

La instalación predeterminada va a `~/.codex/skills/project-plan`. Para instalarlo en otra ruta:

```powershell
powershell -File scripts/install.ps1 -Target D:\path\to\skills\project-plan
```

También se puede copiar `skills/project-plan/` manualmente al directorio de skills de Codex.

### Configuración manual (sin skill)

Si el skill no se ejecuta, o prefieres no delegarlo al agente, inicializa el proyecto en tres pasos:

1. Copia `skills/project-plan/references/PLAN-template.md` como `PLAN.md` en la raíz del proyecto y rellénalo.
2. Añade `skills/project-plan/references/AGENTS-block.md` al final del `AGENTS.md` del proyecto; créalo si no existe.
3. Ejecuta `powershell -File skills/project-plan/scripts/check-plan.ps1 -Path PLAN.md`.

## Uso

### 1. Inicializar un proyecto

Abre la raíz del proyecto en Codex y envía:

```text
Inicializa el plan del proyecto con el skill project-plan.
```

El skill hace lo siguiente:

1. Comprueba si ya existen `PLAN.md` y el bloque de reglas en `AGENTS.md`. Si existen ambos, se detiene.
2. Confirma el objetivo, el criterio de finalización y lo que queda fuera de alcance. Solo pregunta cuando no puede deducirlo de la conversación.
3. Escribe `PLAN.md` en la raíz del proyecto.
4. Escribe `references/AGENTS-block.md` en el bloque marcado de `AGENTS.md` y sustituye el bloque anterior si existe.
5. Ejecuta su `scripts/check-plan.ps1` incluido contra el nuevo `PLAN.md`.

### 2. Trabajar con normalidad

Al iniciar una sesión, Codex lee `PLAN.md` y continúa desde el elemento de «进行中» (en curso). Al terminar una tarea, actualiza el plan y lo incluye en el mismo commit que el código. No hace falta volver a llamar al skill.

### 3. Comprobar el plan (opcional)

```powershell
powershell -File skills/project-plan/scripts/check-plan.ps1 -Path PLAN.md
```

Salida de ejemplo:

```text
[OK] PLAN.md: 29/50 lines, in progress 1, todo 1, warnings 0
```

El script comprueba lo siguiente.

Falla (código de salida `1`):

- Falta una sección obligatoria: 目标 / 非目标 / 进行中 / 待做 / 决策 / 坑
- Un título de sección aparece más de una vez
- 目标 está vacío o sigue siendo un marcador de posición
- 进行中 tiene dos o más tareas sin completar
- Las líneas no vacías superan 50

Avisos (el código de salida no cambia):

- Falta 当前里程碑
- 进行中 no tiene tareas pendientes, o aún contiene `- [x]`
- 待做 aún contiene `- [x]`
- 目标 no contiene «验收» ni «acceptance»
- Hay una tarea en curso y el archivo no se ha modificado en 14 días (`-MaxAgeDays 0` lo desactiva)

«Líneas efectivas» significa líneas no vacías.

## Archivos que se crean en el proyecto

| Archivo | Contenido |
| --- | --- |
| `PLAN.md` | Objetivo, alcance, hito actual, tareas, decisiones, problemas |
| `AGENTS.md` | Contenido existente más un bloque de reglas marcado |

Los nombres de las secciones de `PLAN.md` están fijados en chino. No los traduzcas: el script de comprobación y el bloque de reglas dejarían de coincidir.

| Sección | Contenido |
| --- | --- |
| `## 目标` | Objetivo en una frase, con el criterio de finalización |
| `## 非目标` | Lo que queda explícitamente fuera de alcance |
| `## 当前里程碑` | Nombre del hito actual |
| `## 进行中` | Como máximo una tarea |
| `## 待做` | Tareas pendientes |
| `## 决策` | Fecha, decisión y motivo |
| `## 坑` | Síntoma, causa y solución |
| `## 归档` | Hitos terminados, uno por línea |

Ejemplo:

```markdown
## 目标
Permitir el acceso con correo electrónico; se considera terminado cuando un usuario nuevo puede registrarse e iniciar sesión en menos de tres minutos.

## 非目标
- El acceso con terceros queda fuera de alcance por ahora

## 当前里程碑
M2 Autenticación de usuarios

## 进行中
- [ ] T3 Endpoint de acceso (emisión y renovación de JWT)

## 待做
- [ ] T4 Restablecimiento de contraseña (depende del servicio de correo)

## 决策
- 2026-11-21 Usar JWT en lugar de sesiones: el despliegue debe ser sin estado

## 坑
- prisma migrate necesita PostgreSQL local; sin él devuelve P1001

## 归档
- M1 Esqueleto del proyecto terminado (T1-T2, ver git log)
```

## Reglas del plan

| Regla | Valor |
| --- | --- |
| Tamaño de tarea | Un commit |
| En curso | Como máximo un elemento en la rama principal |
| Longitud del archivo | 50 líneas no vacías como máximo |
| Decisiones | Con fecha y motivo |
| Tareas terminadas | Una línea de archivo por hito |
| Por encima del límite | Archivar primero los hitos; después mover las decisiones y problemas antiguos a `docs/plan-archive.md` |
| Ramas | Cada rama mantiene su propio «进行中»; la rama principal lo reduce a un elemento al fusionar |
| Plan frente a git | Los hechos vienen de `git log`, la intención de `PLAN.md`; los conflictos se confirman manualmente |

## Estructura del repositorio

```text
skills/project-plan/SKILL.md                       Procedimiento de inicialización
skills/project-plan/references/PLAN-template.md    Plantilla del plan
skills/project-plan/references/AGENTS-block.md     Bloque de reglas para AGENTS.md
skills/project-plan/scripts/check-plan.ps1         Comprobación del plan (incluida en el skill)
scripts/install.ps1                                Instalación y limpieza de archivos eliminados
scripts/verify-skill.ps1                           Autoprueba del verificador (15 casos)
.github/workflows/plan-check.yml                   CI: comprobación + aviso de plan sin actualizar
CHANGELOG.md                                       Historial de versiones
```

## Preguntas frecuentes

**El skill no se ejecuta.**
Los skills se seleccionan por su descripción. Nómbralo de forma explícita: «Inicializa el plan del proyecto con el skill project-plan». Si aun así no se ejecuta, usa la configuración manual anterior.

**Una sesión nueva no lee PLAN.md.**
Comprueba que Codex se inicia en la raíz del proyecto o en un subdirectorio, y que `AGENTS.md` contiene el bloque entre `<!-- project-plan:begin -->` y `<!-- project-plan:end -->`. También puedes añadir una línea de respaldo en `~/.codex/AGENTS.md`:

```markdown
- Si existe `PLAN.md` en el directorio de trabajo o en cualquier directorio superior, lee sus secciones 目标 / 进行中 / 决策 / 坑 antes de empezar una tarea; si no existe, ignora esta regla.
```

**El proyecto ya tiene un AGENTS.md. ¿Habrá conflicto?**
No. El bloque se añade al final del archivo y el resto no se modifica. Al repetir la operación solo se sustituye el contenido entre los marcadores.

**¿Dónde debe estar PLAN.md?**
En la raíz del proyecto. Un archivo por repositorio. No lo pongas en una ubicación global.

**¿Hay que hacer commit de PLAN.md?**
Sí. Forma parte del estado del proyecto y debe revisarse como el código. En un repositorio público el plan también pasa a formar parte del historial público; si no es aceptable, usa un repositorio privado o añade `PLAN.md` a `.gitignore` (en ese caso el estado entre sesiones solo existe en local).

**¿Varios proyectos pueden compartir un plan?**
No. Cada raíz de proyecto tiene su propio archivo.

## Desinstalación

1. Elimina `~/.codex/skills/project-plan`.
2. Elimina el bloque entre los dos marcadores de `AGENTS.md`.
3. Elimina `PLAN.md` si ya no lo necesitas.

## Licencia

MIT