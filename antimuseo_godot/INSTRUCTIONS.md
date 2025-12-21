# Guía de Configuración del Anti-Museo en Godot 4.4

Sigue estos pasos para ensamblar el proyecto en el editor de Godot.

### 1. Abrir el Proyecto

1.  Abre Godot 4.4.
2.  En el Gestor de Proyectos, haz clic en **Importar**.
3.  Navega hasta la carpeta `antimuseo_godot` que generamos y selecciona el archivo `project.godot`.
4.  Haz clic en **Instalar y Editar**. El proyecto se abrirá.

### 2. Configurar los Controles (Opcional)

El script del jugador (`player.gd`) ya configura las teclas WASD automáticamente. Si quieres verificarlas o cambiarlas:

1.  Ve a **Proyecto -> Ajustes del Proyecto**.
2.  Selecciona la pestaña **Mapa de Entrada**.
3.  Verás las acciones `up`, `down`, `left`, y `right` asociadas a W, S, A, D.

### 3. Crear la Escena de la "Obra de Arte" (`Artwork.tscn`)

Esta será la plantilla para cada imagen que se muestre.

1.  **Crear Escena Raíz:**
    *   Ve a **Escena -> Nueva Escena**.
    *   Haz clic en **Otro Nodo** y busca `StaticBody3D`. Créalo y renómbralo a `Artwork`.
    *   **Importante:** Un `StaticBody3D` necesita una forma de colisión para que el `RayCast` del jugador lo detecte.

2.  **Añadir la Malla (la imagen visible):**
    *   Selecciona el nodo `Artwork`.
    *   Añade un nodo hijo de tipo `MeshInstance3D`.
    *   En el **Inspector** del `MeshInstance3D`, ve a la propiedad `Mesh` y elige **Nuevo QuadMesh**. Esto crea un plano simple.
    *   **Importante:** Deja el `QuadMesh` con su tamaño por defecto. El material que aplicaremos después lo ajustará.

3.  **Añadir la Colisión:**
    *   Selecciona el nodo `Artwork`.
    *   Añade un nodo hijo de tipo `CollisionShape3D`.
    *   En el **Inspector** del `CollisionShape3D`, ve a la propiedad `Shape` y elige **Nuevo BoxShape3D**.
    *   Ajusta el tamaño del `BoxShape3D` para que coincida aproximadamente con el `QuadMesh` (el tamaño por defecto `1x1x0` está bien).

4.  **Añadir el Script:**
    *   Selecciona el nodo raíz `Artwork`.
    *   En el **Inspector**, ve a la sección `Script` y haz clic en **Cargar**.
    *   Navega a `res://scripts/artwork.gd` y selecciónalo.

5.  **Guardar la Escena:**
    *   Presiona `Ctrl+S`.
    *   Guarda la escena como `Artwork.tscn` en la raíz del proyecto (`res://`).

### 4. Crear la Escena del Jugador (`Player.tscn`)

1.  **Crear Escena Raíz:**
    *   **Escena -> Nueva Escena**.
    *   Elige un nodo `CharacterBody3D` y renómbralo a `Player`.

2.  **Añadir Colisión del Jugador:**
    *   Añade un hijo `CollisionShape3D` al `Player`.
    *   En su propiedad `Shape`, elige **Nuevo CapsuleShape3D**. Ajusta su altura y radio si es necesario.

3.  **Estructura de la Cámara (Cuello y Cabeza):**
    *   Añade un hijo `Node3D` al `Player` y llámalo `Neck`. Este nodo controlará la vista vertical.
    *   Añade un hijo `Camera3D` al `Neck`. Activa la propiedad `Current` en el Inspector de la cámara para que sea la cámara principal.
    *   Añade un hijo `RayCast3D` a la `Camera3D`. Este será el "ojo" del jugador.
        *   En el `RayCast3D`, activa la propiedad `Enabled`.
        *   Asegúrate de que su `Target Position` sea `(0, 0, -4)` o similar, para que mire hacia adelante.

4.  **Añadir y Configurar Script:**
    *   Selecciona el nodo `Player`.
    *   Carga el script `res://scripts/player.gd`.

5.  **Guardar la Escena:**
    *   Presiona `Ctrl+S` y guarda la escena como `Player.tscn` en la raíz (`res://`).

### 5. Crear la Escena Principal (`main.tscn`)

Este es el escenario principal que une todo.

1.  **Crear Escena Raíz:**
    *   **Escena -> Nueva Escena**.
    *   Elige un nodo `Node3D` y llámalo `Main`.

2.  **Añadir el Entorno (Niebla y Fondo):**
    *   Añade un hijo `WorldEnvironment` al nodo `Main`.
    *   En el Inspector, en `Environment`, elige **Nuevo Environment**.
    *   Haz clic en el recurso `Environment` para editarlo.
    *   En la sección **Background**:
        *   Cambia `Mode` a `Color`.
        *   Elige un color oscuro para `Color` (ej: `#1a1a1a`).


3.  **Añadir Luz Básica:**
    *   Añade un hijo `DirectionalLight3D`. No necesita configuración extra, es solo para que los modelos no se vean completamente negros si decides cambiar los materiales.

4.  **Añadir al Jugador:**
    *   Arrastra el archivo `Player.tscn` desde el **FileSystem dock** a la escena `Main`.
    *   Coloca al jugador en la posición `(0, 1, 0)`.

5.  **Añadir el Spawner de Obras:**
    *   Añade un hijo `Node3D` al nodo `Main` y llámalo `ArtworkSpawner`.
    *   Selecciona `ArtworkSpawner` y carga el script `res://scripts/artwork_spawner.gd`.
    *   Verás dos propiedades exportadas en el Inspector:
        *   **Artwork Scene:** Arrastra el archivo `Artwork.tscn` desde el FileSystem a esta propiedad.
        *   **Images Path:** Ya está configurado como `res://assets/MUSEO TRAVESTI`, que es correcto.

6.  **Guardar y Configurar como Escena Principal:**
    *   Presiona `Ctrl+S` y guarda la escena como `main.tscn`.
    *   El archivo `project.godot` ya está configurado para usar `main.tscn` como la escena de inicio.

### 6. Integrar el Modelo `dragona.glb`

Vamos a añadir la dragona como una pieza central que dialoga con el jugador.

1.  **Importar el Modelo:**
    *   En el panel de **FileSystem**, navega a `res://assets/`. Verás el archivo `dragona.glb`.
    *   Haz doble clic en `dragona.glb` para abrir el diálogo de importación avanzada. Simplemente haz clic en **Reimportar** con los ajustes por defecto.
    *   Godot crea una escena a partir del modelo. Verás un nuevo icono de escena `dragona.tscn` junto al `.glb`.

2.  **Crear la Escena Interactiva de la Dragona:**
    *   Haz doble clic en la escena `dragona.tscn` recién creada para abrirla.
    *   El nodo raíz es un `Node3D`. Necesitamos cambiarlo para que sea interactivo.
    *   Haz clic derecho en el nodo raíz y elige **Cambiar Tipo**. Selecciona `StaticBody3D`.
    *   **Importante:** El `RayCast` solo detecta `Area3D` o `PhysicsBody3D` (como `StaticBody3D`).
    *   Añade un `CollisionShape3D` como hijo del `StaticBody3D` raíz. En el Inspector, para su `Shape`, elige **Crear Trimesh Shape Estática**. Esto crea una colisión que se ajusta perfectamente a la forma del modelo, lo cual es ideal para objetos complejos.

3.  **Añadir el Texto del Diálogo:**
    *   Añade un nodo `Label3D` como hijo del `StaticBody3D` raíz.
    *   En el **Inspector** del `Label3D`:
        *   **Text:** Escribe el texto que quieres que aparezca. Por ejemplo: "Soy el archivo que se resiste a ser leído."
        *   **Font Size:** Aumenta el tamaño de la fuente a `120` o `160` para que sea legible desde lejos.
        *   **Billboard:** Cambia el modo a `Enabled` o `Y-Billboard` para que el texto siempre mire al jugador.
        *   Ajusta la posición del `Label3D` para que flote sobre o junto al modelo de la dragona.

4.  **Añadir el Script de Comportamiento:**
    *   Selecciona el nodo raíz (`StaticBody3D`).
    *   Carga el script `res://scripts/dragona.gd`.
    *   El script se encargará automáticamente de mostrar/ocultar el `Label3D`.

5.  **Guardar la Escena Mejorada:**
    *   Guarda la escena (`Ctrl+S`).

6.  **Añadir la Dragona a la Escena Principal:**
    *   Abre `main.tscn`.
    *   Arrastra tu escena `dragona.tscn` (la que tiene el icono de escena, no el `.glb`) a la vista 3D.
    *   Colócala en una posición central o significativa, por ejemplo `(0, 2, -10)`.

### 7. ¡Probar el Proyecto!

Presiona **F5**. Ahora, además de las obras que escapan, verás el modelo de la dragona. Cuando la mires, aparecerá el texto que configuraste.

**Controles:**
*   **WASD:** Moverse.
*   **Mouse:** Mirar alrededor.
*   **Escape:** Liberar/Capturar el cursor del mouse.