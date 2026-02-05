# TaskOverlay

Un overlay flotante para macOS que te ayuda a recordar en qué estás trabajando.

![Estilo similar al overlay de Discord]

## Características

- **Overlay flotante**: Siempre visible arriba a la izquierda de tu pantalla
- **Persiste entre reinicios**: Guarda automáticamente tus tareas y su estado
- **Funciona en todos los espacios**: Visible en todos los escritorios y apps a pantalla completa
- **Icono en barra de menú**: Control rápido desde la barra de menú con contador de tareas pendientes
- **No aparece en el Dock**: Solo muestra el icono en la barra de menú
- **Arrastrable**: Puedes mover el overlay a donde quieras
- **Control total desde teclado**: No necesitas usar el ratón

## Atajos de teclado

### Global
- `⌃⇧Space` - Mostrar/Ocultar overlay

### Navegación
- `↑/↓` - Navegar entre tareas (auto-scroll cuando hay muchas)
- `Cmd+↑` - Ir a la primera tarea
- `Cmd+↓` - Ir a la última tarea  
- `PageUp/PageDown` - Saltar 5 tareas arriba/abajo

### Acciones
- `Enter` - Editar tarea seleccionada
- `Backspace` - Eliminar tarea
- `Space` - Marcar/desmarcar como completada
- `⌥↑/⌥↓` - Mover tarea arriba/abajo
- `Escape` - Ocultar overlay
- `Cualquier letra` - Crear nueva tarea

### Scroll visual
- **▲** aparece cuando hay tareas arriba del viewport
- **▼** aparece cuando hay tareas debajo del viewport
- Contador `3/15` muestra posición actual

## Prioridades

Puedes asignar prioridades a tus tareas:

- **🔴 Alta**: Escribe `A ` antes del texto (ej: "A llamar al cliente")
- **🟡 Media**: Sin prefijo (ej: "revisar código")
- **🟢 Baja**: Escribe `B ` antes del texto (ej: "B actualizar documentación")

Las tareas completadas se muestran con tachado y se ordenan al final.

## Accesibilidad

- Etiquetas VoiceOver para todas las tareas
- Indicadores visuales no solo por color (iconos de check, tachado en texto)
- Feedback visual claro para el estado seleccionado

## Cómo usar

1. Abre `TaskOverlay.xcodeproj` en Xcode
2. Selecciona tu Team de desarrollo en Signing & Capabilities (o desactiva code signing para pruebas locales)
3. Pulsa `⌘R` para compilar y ejecutar
4. El overlay aparecerá arriba a la izquierda
5. Usa `⌃⇧Space` para mostrar/ocultar
6. Escribe cualquier letra para añadir una tarea nueva
7. Usa `Space` para marcar tareas como completadas

## Requisitos

- macOS 12.0 o superior
- Xcode 15.0 o superior

## Personalización

Puedes modificar fácilmente en `AppDelegate.swift`:

- **Posición**: Cambia `margin` y las coordenadas en `setupPanel()`
- **Tamaño**: Ajusta `panelWidth` y `panelHeight`
- **Colores**: Modifica los colores de prioridad en `updateAppearance()`
- **Estilo visual**: Cambia `containerView.material` (opciones: `.hudWindow`, `.popover`, `.menu`, etc.)

## Estructura del proyecto

```
TaskOverlay/
├── TaskOverlay.xcodeproj/
└── TaskOverlay/
    ├── AppDelegate.swift    # Toda la lógica de la app
    ├── Info.plist           # Configuración (LSUIElement=true para no aparecer en Dock)
    └── TaskOverlay.entitlements
```

## Historial de cambios

### v2.0
- ✅ Estado de completado con `Space`
- 🔄 Reordenamiento con `⌥↑/⌥↓`
- 🎨 Sistema de prioridades (Alta/Media/Baja)
- 📊 Contador de tareas pendientes en menú
- ♿ Mejoras de accesibilidad (VoiceOver)
- 📜 Indicador de scroll cuando hay muchas tareas
- ✨ Tachado en texto completado
- 🔵 Iconos de checkmark para tareas completadas

### v1.0
- Lanzamiento inicial
