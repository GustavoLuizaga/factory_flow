# Factory Flow

Juego móvil 2D de gestión de producción desarrollado en Godot Engine 4.x. Combina materiales usando cintas transportadoras y máquinas de fusión para crear nuevos productos.

## 🎮 Concepto del Juego

Factory Flow es un juego tipo puzzle/automation donde debes:
1. **Materiales** aparecen automáticamente en la parte superior del tablero
2. **Arrastra cintas transportadoras** del menú al tablero para guiar los materiales
3. **Coloca máquinas de fusión** para combinar 2 materiales
4. **Crea productos nuevos** siguiendo las recetas correctas

## 📋 Requisitos Previos

Antes de empezar, asegúrate de tener instalado:

- **Godot Engine 4.x** - [Descargar aquí](https://godotengine.org/download)
  - Versión recomendada: 4.2 o superior
  - Puedes usar la versión estándar o Mono (C#)

## 🚀 Configuración Inicial

### 1. Clonar el Repositorio

```bash
git clone https://github.com/GustavoLuizaga/factory_flow.git
cd factory_flow
```

### 2. Abrir el Proyecto en Godot

#### Opción A: Desde Godot Editor
1. Abre **Godot Engine**
2. En el Project Manager, haz clic en **"Import"** (Importar)
3. Navega hasta la carpeta del proyecto clonado
4. Selecciona el archivo `project.godot`
5. Haz clic en **"Import & Edit"** (Importar y Editar)

#### Opción B: Desde la Terminal
```bash
# Windows (ajusta la ruta según tu instalación)
"C:\Program Files\Godot\Godot_v4.x_stable_win64.exe" --path . --editor

# Linux
godot --path . --editor

# macOS
/Applications/Godot.app/Contents/MacOS/Godot --path . --editor
```

### 3. Primera Ejecución

La primera vez que abras el proyecto:
- Godot importará automáticamente todos los assets
- Esto puede tomar unos minutos dependiendo del tamaño del proyecto
- Verás una barra de progreso de importación
- Los archivos `.import` se generarán automáticamente (estos están en `.gitignore`)

## ▶️ Ejecutar el Proyecto

Una vez abierto el proyecto en el editor:

1. **Presiona F5** o haz clic en el botón **"Play"** (▶️) en la esquina superior derecha
2. Si es la primera vez, Godot te pedirá que selecciones la escena principal
3. Selecciona la escena de inicio del proyecto

### Atajos de Teclado Útiles

- **F5** - Ejecutar el proyecto
- **F6** - Ejecutar la escena actual
- **F7** - Pausar la escena
- **F8** - Detener la ejecución
- **Ctrl + B** - Configurar Build/Export

## 🔧 Solución de Problemas

### El proyecto no importa correctamente
- Asegúrate de estar usando **Godot 4.x** (no Godot 3.x)
- Elimina la carpeta `.godot/` y vuelve a abrir el proyecto

### Errores de importación de assets
- Ve a **Project > Reimport Assets** en el menú de Godot
- Espera a que termine la reimportación

### Conflictos de Git con archivos `.import`
- Los archivos `.import` están en `.gitignore` y no deberían causar conflictos
- Si ocurren, simplemente elimínalos localmente y Godot los regenerará:
  ```bash
  git checkout --theirs archivo.import
  ```

## 📝 Notas Adicionales

- **NO** subas archivos `.import` al repositorio (ya están en `.gitignore`)
- **NO** subas la carpeta `.godot/` (ya está en `.gitignore`)
- Si agregas assets grandes (>10MB), considera usar Git LFS
