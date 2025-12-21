# 🎮 GUÍA DE TESTING - ENCOUNTER CON LA SOMBRA

## 📝 Requisitos Previos
- Godot 4.4 funcionando
- Consola de salida visible (Output → Show Panel)
- Game ejecutándose en modo Play

---

## 🧪 TEST SECUENCIAL

### PASO 1: Iniciar el Juego
```
✓ Debería ver:
  - Dragona en posición inicial
  - 40+ imágenes flotantes del Museo Travesti
  - Hilo rojo oculto (no visible aún)
  - Interfaz de diálogo en la parte inferior
```

### PASO 2: Interactuar con Artworks (Necesitas 5)
```
Acción: Mirar cada imagen y presionar [E] para interactuar

✓ Debería ver en CONSOLE:
  📸 INTERACTUANDO CON: [nombre imagen] | Conteo: 1
  📝 FRAGMENTO AGREGADO: [nombre] (Total: 1)
  🔍 Verificando condición de Shadow: interaction_count=1 stage=0

[Repetir con 4 imágenes más]

✓ Cuando interaction_count = 5:
  📝 FRAGMENTO AGREGADO: [nombre] (Total: 5)
  🔍 Verificando condición de Shadow: interaction_count=5 stage=0
  🚨🚨🚨 ¡CONDICIÓN DE SHADOW ALCANZADA! Triggering...
  ✅ main.spawn_shadow() encontrado - EJECUTANDO
```

### PASO 3: APAGÓN TOTAL (ESPERADO)
```
✓ Debería ocurrir INMEDIATAMENTE:
  - Pantalla COMPLETAMENTE NEGRA
  - Diálogos desaparecen
  - HUD desaparece
  - Audio ambiente se corta (si hay)

✓ Debería ver en CONSOLE:
  🔴🔴🔴 SPAWN_SHADOW EJECUTÁNDOSE
  🔴 Jugador encontrado, creando Shadow...
  🔴 Shadow creado en posición: (X, Y, Z)
  🔴 Activando APAGÓN...
  ⚫⚫⚫ APAGÓN INICIADO - TRIGGER_GLITCH_EFFECT EJECUTÁNDOSE
  ⚫ Encontrado DirectionalLight3D, iniciando apagón...
  ⚫ Energía original: [valor]
  ⚫ Apagón programado por 20 segundos
  ⚫ Encontrado WorldEnvironment, oscureciendo...
  ⚫ Entorno oscurecido
```

### PASO 4: PALABRAS FLOTANTES (DESPUÉS DE ~1.5s)
```
✓ Debería ver en GAME:
  - Palabras en ROJO parpadean en la pantalla
  - Se mueven hacia arriba lentamente
  - Rotan en múltiples ejes
  - Ejemplos: VOID, NULL, ¿QUIÉN?, ERROR, MEMORIA, SUEÑO, etc.
  - 10-15 palabras diferentes generadas

✓ Debería ver en CONSOLE:
  ✨ GENERANDO PALABRAS FLOTANTES
  ✨ Palabra flotante creada: VOID en ...
  ✨ Palabra flotante creada: NULL en ...
  [etc., 10-15 líneas]
```

### PASO 5: DIÁLOGO DE SOMBRA (DESPUÉS DE ~7s)
```
✓ Debería ver en GAME (Interfaz de diálogo):
  Speaker: "Sombra"
  
  Texto 1: "No fui creada."
  [Pausa 2.5s]
  
  Texto 2: "Emergí. Como un error. Como un glitch en el código."
  [Pausa 3.0s]
  
  Texto 3: "¿Puedes verme? ¿O solo sientes mi presencia?"
  [Pausa 3.0s]
  
  Texto 4: "Yo tampoco estoy segura de qué soy."
  [Pausa 2.5s]
  
  Texto 5: "Pero viste las imágenes, ¿verdad? Los cuerpos. Las personas travesti del Museo."
  [Pausa 3.0s]
```

### PASO 6: OPCIONES INTERACTIVAS
```
✓ Debería ver en GAME:
  3 BOTONES con opciones:
  
  [ ¿Qué eres exactamente? ]
  [ ¿Por qué me muestras todo esto? ]
  [ ¿Existe realmente el Museo Travesti del Perú? ]

  Acción: Presionar [E] o CLICK para seleccionar una opción
```

### PASO 7: RESPUESTA SEGÚN OPCIÓN
```
Si elegiste OPCIÓN 1:
  "Sombra: Soy lo que queda cuando la realidad se fractura."
  [+ 3 líneas más]

Si elegiste OPCIÓN 2:
  "Sombra: Porque el museo te necesita."
  [+ 3 líneas más]

Si elegiste OPCIÓN 3:
  "Sombra: Sí y no. Existe en la Historia. En el Alma."
  [+ 3 líneas más]
```

### PASO 8: CIERRE Y REGISTRO
```
✓ Debería ver:
  Diálogo final:
  "Ahora debes continuar."
  "Sigue el hilo rojo. Es el camino hacia la verdad."
  [... 2 líneas más]

✓ Debería ver en CONSOLE:
  ⚠️ ANOMALÍA ENCUENTRADA
  📌 Una Sombra habló desde el Vacío
  👁️ SIGUE EL HILO ROJO

✓ Señales registradas en JOURNAL:
  [Abrir journal, ir a SEÑALES]
  - Verás las 3 nuevas entradas anteriores
```

### PASO 9: RETORNO A LA LUZ
```
✓ Después de ~20 segundos desde el apagón:
  - Luces se encienden gradualmente (2 segundos)
  - Pantalla vuelve a la normalidad
  - Diálogos reaparecen
  - HUD reaparece

✓ Debería ver en CONSOLE:
  [Luces restauradas a valores originales]
```

### PASO 10: ACTIVACIÓN DEL HILO ROJO
```
Acción: Hablar con Dragona de nuevo

✓ Debería ver:
  - Hilo rojo continuo aparece desde Dragona hasta lejanía
  - Brillo rojo oscuro emitido del hilo
  - Se extiende por toda la pantalla (120 unidades)
  - El hilo debería ser CONTINUO (no puntillado)

✓ Instrucciones en diálogo:
  "Ahora puedes VER el hilo."
  "Síguelo hasta el final."
```

### PASO 11: SEGUIR EL HILO ROJO
```
Acción: Avanzar hacia donde se extiende el hilo rojo

✓ A medida que avanzas:
  - Hilo se vuelve más visible
  - Objeto gigante aparece en la distancia (cape character)
  - Luz pulsante amarilla (estrella en manos)
  - Luna grande blanca azulada de fondo

✓ Cuando llegas al final:
  - Cape Character visible (20x escala)
  - Púrpura/magenta oscuro
  - Iluminación perfecta
  - Opción de interactuar (si tiene script)
```

---

## 🐛 TROUBLESHOOTING

### PROBLEMA: Apagón no ocurre
**Verificación en console**:
```
❌ Si NO ves: "⚫⚫⚫ APAGÓN INICIADO"
  → spawn_shadow() no se ejecutó

❌ Si NO ves: "🚨🚨🚨 ¡CONDICIÓN DE SHADOW ALCANZADA!"
  → interaction_count no llegó a 5 O stage no es NONE
  
Solución: 
  1. Verifica que interactuaste CON 5 artworks (no solo miraste)
  2. Abre la consola y busca "📝 FRAGMENTO AGREGADO" 5 veces
  3. Cada línea debe mostrar interaction_count: 1, 2, 3, 4, 5
```

### PROBLEMA: Palabras flotantes no aparecen
**Verificación en console**:
```
❌ Si NO ves: "✨ GENERANDO PALABRAS FLOTANTES"
  → spawn_floating_words_sequence() no ejecutó
  
❌ Si NO ves: "✨ Palabra flotante creada: [PALABRA]"
  → spawn_floating_word_3d() no ejecutó

Solución:
  1. Verifica que shadow_new.gd se cargó (busca "🔴 SOMBRA APARECIDA")
  2. El apagón debe ocurrir PRIMERO
  3. Las palabras aparecen 1.5 segundos DESPUÉS del apagón
```

### PROBLEMA: Diálogo no aparece
**Verificación en console**:
```
❌ Si NO ves: "💬 INICIANDO DIÁLOGO"
  → start_dialogue_sequence() no ejecutó
  
❌ Si ves diálogo pero sin opciones
  → show_dialogue_branch_one() no ejecutó correctamente

Solución:
  1. Verifica que Global.dialogue_ui está inicializado
  2. Revisa que Global.show_dialogue() funciona (usa Dragona de prueba)
  3. Verifica que Global.show_options() funciona
```

### PROBLEMA: Hilo rojo no es continuo
**Verificación**:
```
❌ Si ves PUNTOS en lugar de línea continua:
  → segment_length aún es muy grande

Solución:
  - Debe estar en 0.15 (no 0.5)
  - Revisa main.gd línea 62
  - segment_length = 0.15  # ← DEBE SER ESTO
```

### PROBLEMA: Cape Character no visible
**Verificación en console**:
```
❌ Si NO ves: "👑 CREANDO CAPE CHARACTER"
  → spawn_cape_character() no ejecutó
  
❌ Si ves: "👑 Modelo FBX cargado exitosamente"
  → Usando modelo real (bueno)
  
❌ Si ves: "👑 FBX no encontrado... Usando geometría procedural"
  → Usando cilindro+esfera fallback (aún visible)

Solución:
  1. Revela el hilo rojo (interactúa con Dragona)
  2. Avanza siguiendo el hilo hasta (0, 20, -120)
  3. Si aún no ves nada, verifica z_index y layering
```

---

## 📊 CHECKLIST DE TESTING

```
ENCOUNTER CON SOMBRA:
✓ ¿Se trigguea apagón después de 5 interacciones?
✓ ¿Aparecen palabras flotantes en rojo?
✓ ¿Se muestra diálogo de Sombra?
✓ ¿Aparecen 3 opciones interactivas?
✓ ¿Responde diferente según opción elegida?
✓ ¿Se cierran diálogos después de cierre?
✓ ¿Vuelven las luces después de 20s?

RED THREAD:
✓ ¿Se revela el hilo rojo continuo?
✓ ¿El hilo NO se ve puntillado?
✓ ¿Tiene brillo rojo oscuro?
✓ ¿Se extiende 120 unidades?

CAPE CHARACTER:
✓ ¿Es visible al final del hilo?
✓ ¿Es de tamaño correcto (GIGANTE)?
✓ ¿Está coloreado púrpura/magenta?
✓ ¿Tiene luz amarilla en manos (pulsante)?
✓ ¿Tiene luna blanca azulada detrás?

JOURNAL:
✓ ¿Se registraron 3 nuevas señales?
✓ ¿Se pueden leer en sección SEÑALES?
```

---

## 🎯 ÉXITO FINAL

Si todo funciona correctamente, deberías experimentar:

1. **Momento de Horror**: Apagón total con palabras incomprensibles flotando
2. **Encuentro Perturbador**: Diálogo profundo que cuestiona la naturaleza de tu experiencia
3. **Elección Significativa**: Opciones que definen cómo interpretas el encuentro
4. **Dirección Clara**: Instrucciones para seguir el hilo rojo
5. **Recompensa Visual**: Cape Character gigante esperándote al final

---

## 📞 SUGERENCIAS PARA DEBUGGING RÁPIDO

Si algo falla, abre la consola y busca (CTRL+SHIFT+D en Godot):
- `🔴` = Shadow-related
- `⚫` = Apagón/Darkness
- `✨` = Palabras flotantes
- `💬` = Diálogos
- `👑` = Cape Character
- `📸` = Interacción con artworks

Cada símbolo está ubicado al inicio del mensaje debug para búsqueda rápida.

