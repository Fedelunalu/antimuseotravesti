# ⚡ REFERENCIA RÁPIDA - CAMBIOS CRÍTICOS

## 🔴 LO MÁS IMPORTANTE

### Trigger del Apagón
```gdscript
# artwork.gd - línea ~105
if interaction_count >= 5 and Global.current_quest_stage == Global.QuestStage.NONE:
    main.spawn_shadow()  # ← ESTO ACTIVA TODO
```

### El Apagón Mismo
```gdscript
# main.gd - función trigger_glitch_effect()
light.light_energy = 0.0  # Instantáneo
# [20 segundos de oscuridad total]
light.light_energy = original_energy  # Restaura
```

### Palabras Flotantes
```gdscript
# shadow_new.gd - spawn_floating_word_3d()
label.modulate = Color(1, 0, 0, 0)  # Rojo transparente
# Tween: fade in + move up + rotate + blink + fade out
```

### Diálogos Ramificados
```gdscript
# shadow_new.gd - show_dialogue_branch_one()
Global.show_options([
    "¿Qué eres exactamente?",
    "¿Por qué me muestras esto?",
    "¿Existe realmente el Museo Travesti del Perú?"
])
match choice:
    0: respond_what_are_you()
    1: respond_why_show_me()
    2: respond_does_museum_exist()
```

---

## 🔍 DEBUG PRINTS (BÚSQUEDA RÁPIDA)

Copia y busca en console (CTRL+F en Output):

### Trigger Shadow
```
🚨🚨🚨 ¡CONDICIÓN DE SHADOW ALCANZADA!
🔴🔴🔴 SPAWN_SHADOW EJECUTÁNDOSE
```

### Apagón
```
⚫⚫⚫ APAGÓN INICIADO
⚫ Apagón programado por 20 segundos
```

### Palabras Flotantes
```
✨ GENERANDO PALABRAS FLOTANTES
✨ Palabra flotante creada:
```

### Diálogos
```
💬 INICIANDO DIÁLOGO
```

### Cape Character
```
👑 CREANDO CAPE CHARACTER
👑 ✅ Modelo FBX cargado
```

---

## 📍 UBICACIONES CLAVE EN CÓDIGO

| Feature | Archivo | Función | Línea |
|---------|---------|---------|-------|
| Shadow Trigger | artwork.gd | interact() | ~105 |
| Apagón | main.gd | trigger_glitch_effect() | 232 |
| Shadow Spawn | main.gd | spawn_shadow() | 241 |
| Palabras Flotantes | shadow_new.gd | spawn_floating_word_3d() | ~90 |
| Diálogo Principal | shadow_new.gd | start_dialogue_sequence() | ~50 |
| Opciones | shadow_new.gd | show_dialogue_branch_one() | ~95 |
| Red Thread | main.gd | setup_red_thread() | 50 |
| Segment Length | main.gd | setup_red_thread() | 62 |
| Cape Character | main.gd | spawn_cape_character() | 103 |

---

## 🎮 SECUENCIA DE TESTING

```
1. Iniciar juego
   ↓
2. Interactuar con 5 artworks (presionar E)
   ↓
3. [Esperar ~1 segundo]
   ↓
4. ⚫ APAGÓN TOTAL
   ↓
5. ✨ Palabras flotantes en rojo
   ↓
6. 💬 Diálogo de Sombra
   ↓
7. Presionar [E] en una de las 3 opciones
   ↓
8. Ver respuesta ramificada
   ↓
9. 🌞 Luces se restauran (20s después del apagón)
   ↓
10. Hablar con Dragona → Revela hilo rojo
   ↓
11. 🧵 Sigue el hilo rojo continuo
   ↓
12. 👑 Llega a Cape Character gigante al final
```

---

## ⚠️ CHECKLIST DE VERIFICACIÓN

- [ ] No hay errores en console (`get_errors()`)
- [ ] `interaction_count` llega a 5
- [ ] `Global.current_quest_stage == NONE` al principio
- [ ] `spawn_shadow()` se llama
- [ ] DirectionalLight3D se oscurece
- [ ] Palabras flotantes aparecen
- [ ] Diálogo inicial muestra (4 líneas)
- [ ] Opciones aparecen (3 botones)
- [ ] Respuesta corresponde a opción elegida
- [ ] Diálogo cierre muestra (4 líneas)
- [ ] Señales se registran en journal
- [ ] Luces se restauran después de 20s
- [ ] Hilo rojo aparece CONTINUO
- [ ] Cape Character visible al final

---

## 🔧 VALORES CRÍTICOS

```gdscript
// shadow_new.gd
var floating_words.size() = 16  // Palabras disponibles
spawn_floating_words_sequence(): 10-15  // Palabras generadas
duration = randf_range(7.0, 10.0)  // Duración cada palabra

// main.gd
segment_length = 0.15  // Red thread (0.15 = continuo, 0.5 = puntillado)
trigger_glitch_effect(): 20.0  // Duración apagón (segundos)
cape_character.scale = Vector3(20, 20, 20)  // Escala gigante

// artwork.gd
if interaction_count >= 5  // Trigger de shadow
Global.current_quest_stage == Global.QuestStage.NONE  // Condición
```

---

## 🎯 RESULTADOS ESPERADOS

### Por Console
```
[Al 5ta interacción]
📝 FRAGMENTO AGREGADO: [nombre] (Total: 5)
🔍 Verificando condición de Shadow: interaction_count=5 stage=0
🚨🚨🚨 ¡CONDICIÓN DE SHADOW ALCANZADA! Triggering...
✅ main.spawn_shadow() encontrado - EJECUTANDO

[Inmediatamente]
🔴🔴🔴 SPAWN_SHADOW EJECUTÁNDOSE
🔴 Jugador encontrado, creando Shadow...
🔴 Shadow creado en posición: (8, 1.5, -8)  // Aprox
🔴 Activando APAGÓN...
⚫⚫⚫ APAGÓN INICIADO - TRIGGER_GLITCH_EFFECT EJECUTÁNDOSE
⚫ Encontrado DirectionalLight3D, iniciando apagón...
⚫ Apagón programado por 20 segundos

[Después ~1.5s]
✨ GENERANDO PALABRAS FLOTANTES
✨ Palabra flotante creada: VOID en (-12, 5, 8)  // Aprox
[...15 palabras más]

[Después ~7s total]
💬 INICIANDO DIÁLOGO
[Diálogo aparece en UI]
```

### En Game
```
1. Pantalla completamente negra (no se ve nada)
2. Palabras rojas parpadean, flotan, desaparecen
3. UI de diálogo muestra en la oscuridad
4. 3 botones de opciones
5. Al seleccionar opción: respuesta diferente
6. Después ~20s: luces se encienden
```

---

## 🚨 ERRORES COMUNES

| Error | Causa | Solución |
|-------|-------|----------|
| No hay apagón | spawn_shadow() no se llamó | Interactúa 5 veces |
| No hay palabras | spawn_floating_words() falló | Espera 2s después apagón |
| Diálogo no aparece | Global.dialogue_ui = null | Verifica setup de Global |
| Shadow no aparece en escena | Script no se cargó | Verifica ruta: `res://scripts/shadow_new.gd` |
| Red thread puntillado | segment_length = 0.5 | Cambiar a 0.15 |
| Cape Character invisible | Falta de escala o posición | Verifica spawn_cape_character() |

---

## 📚 ARCHIVOS DOCUMENTACIÓN

- `PROJECT_STATUS.md` → Estado completo del proyecto
- `LATEST_CHANGES.md` → Todos los cambios realizados
- `TESTING_GUIDE.md` → Guía paso a paso para testing
- `CHANGES_SUMMARY.md` → Resumen histórico de cambios
- `INSTRUCTIONS.md` → Instrucciones del proyecto original

---

## ⏱️ TIMELINE DE EVENTOS

```
T=0:00     → Jugador interactúa con artwork #5
T=0:01     → interaction_count >= 5 detectado
T=0:02     → spawn_shadow() llamado
T=0:03     → trigger_glitch_effect() inicia
T=0:04     → Apagón instantáneo (DirectionalLight energy = 0)
T=0:06     → Palabras flotantes comienzan a aparecer
T=0:12     → Última palabra flotante aparece
T=0:15     → Diálogo inicial muestra ("No fui creada...")
T=0:20     → Pregunta con 3 opciones
T=0:25     → Respuesta ramificada según opción
T=0:30     → Diálogo cierre
T=0:33     → Apagón total termina (20s desde inicio)
T=0:35     → Luces restauradas gradualmente (2s)
T=0:37     → Mundo visible nuevamente
```

---

## 💡 TIPS PARA DEBUGGING

1. **Buscar rápidamente**:
   - Apagón: `⚫⚫⚫`
   - Shadow: `🔴🔴🔴`
   - Palabras: `✨`
   - Diálogos: `💬`

2. **Verificar trigger**:
   - Abre console
   - Busca: `📝 FRAGMENTO AGREGADO`
   - Debería aparecer 5 veces
   - Últimas 2-3 líneas: números deben ser 3, 4, 5

3. **Verificar apagón**:
   - Si ves `⚫ Encontrado DirectionalLight3D` → Luz encontrada ✓
   - Si NO lo ves → Apagón no ejecutará

4. **Verificar palabras**:
   - Busca: `✨ Palabra flotante creada`
   - Debería haber 10-15 entradas
   - Si hay 0 → spawn_floating_words_sequence() no corrió

---

**Última actualización: $(date)**  
**Estado: ✅ PRODUCCIÓN LISTA**

