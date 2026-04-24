# Parcial 2 — Accidentes Tuluá + CRUD Establecimientos

Aplicación Flutter que integra dos módulos principales:

1. **Estadísticas de Accidentes de Tránsito** — consume datos abiertos de Tuluá, los procesa con un Isolate y visualiza 4 gráficas interactivas.
2. **CRUD de Establecimientos** — gestión completa (crear, leer, actualizar, eliminar) de establecimientos de parqueadero, incluyendo carga de logo.

---

## APIs Consumidas

### API 1 — Accidentes de Tránsito (Datos Abiertos Colombia)

| Campo | Descripción |
|---|---|
| **URL Base** | `https://www.datos.gov.co/resource/ezt8-5wyj.json` |
| **Método** | `GET` con `$limit=100000` |
| **Autenticación** | No requiere |

**Campos relevantes del JSON:**

```json
{
  "a_o": "2023",
  "fecha": "2023-01-03T00:00:00.000",
  "dia": "martes",
  "hora": "15:40:00",
  "area": "URBANA",
  "barrio_hecho": "SAJONIA",
  "clase_de_accidente": "CHOQUE",
  "gravedad_del_accidente": "CON HERIDOS",
  "clase_de_vehiculo": "MOTOCICLETA"
}
```

### API 2 — Establecimientos (Parking VisionTIC)

| Campo | Descripción |
|---|---|
| **URL Base** | `https://parking.visiontic.com.co/api` |
| **Documentación** | [Swagger](https://parking.visiontic.com.co/api/documentation) |

**Endpoints utilizados:**

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/establecimientos` | Listar todos |
| `GET` | `/establecimientos/{id}` | Ver uno |
| `POST` | `/establecimientos` | Crear (multipart/form-data) |
| `POST` | `/establecimiento-update/{id}` | Editar (con `_method=PUT`) |
| `DELETE` | `/establecimientos/{id}` | Eliminar |

**Ejemplo de respuesta JSON:**

```json
{
  "success": true,
  "data": [
    {
      "id": 41,
      "nombre": "Pruebas",
      "nit": "12334555",
      "direccion": "Carrea 31A # 6A - 89",
      "telefono": "32106456567",
      "logo": "68f0ff06d3532.png",
      "estado": "A"
    }
  ]
}
```

> **Nota:** La API usa *method spoofing* de Laravel para el update: se envía `POST` con el campo `_method=PUT` en el `form-data`.

---

## ¿Cuándo usar `Future/async/await` vs `Isolate`?

| Aspecto | `Future` / `async` / `await` | `Isolate` |
|---|---|---|
| **Caso de uso** | Operaciones I/O (HTTP, archivos, BD) | Cómputo pesado (procesamiento de datos) |
| **Hilo** | Se ejecuta en el hilo principal | Se ejecuta en un hilo separado |
| **Bloqueo de UI** | No bloquea (es asíncrono cooperativo) | No bloquea (es paralelismo real) |
| **Ejemplo** | `await dio.get(...)` | Procesar 100,000 registros JSON |

### ¿Por qué Isolate para las estadísticas?

El endpoint de accidentes retorna **miles de registros** que requieren:
- Iterar sobre todos los registros múltiples veces
- Normalizar textos (tildes, mayúsculas)
- Contar frecuencias por categoría
- Ordenar por cantidad

Este procesamiento es **CPU-intensive** y bloquearía el hilo principal causando jank en la UI. Al usar `Isolate.run()`, el cálculo se ejecuta en un hilo separado, manteniendo la interfaz fluida.

```dart
// El procesamiento se delega completamente al Isolate
final result = await Isolate.run(() => _computeEstadisticas(rawData));
```

**Mensajes en consola requeridos:**
```
[Isolate] Iniciado — N registros recibidos
[Isolate] Completado en X ms
```

---

## Arquitectura y Estructura del Proyecto

```
lib/
├── main.dart                          # Entry point + dotenv + MaterialApp.router
├── config/
│   └── app_router.dart                # GoRouter — rutas declarativas
├── models/
│   ├── accidente.dart                 # Modelo Accidente (fromJson)
│   └── establecimiento.dart           # Modelo Establecimiento (fromJson/toJson)
├── services/
│   ├── accidente_service.dart         # Dio — GET accidentes
│   └── establecimiento_service.dart   # Dio — CRUD establecimientos (multipart)
├── isolates/
│   └── accidente_isolate.dart         # Isolate.run() — 4 estadísticas
├── views/
│   ├── home_screen.dart               # Dashboard con resumen + navegación
│   ├── accidentes/
│   │   └── estadisticas_screen.dart   # 4 gráficas fl_chart
│   └── establecimientos/
│       ├── listado_screen.dart        # ListView.builder + Skeleton
│       ├── detalle_screen.dart        # Detalle + eliminar
│       └── formulario_screen.dart     # Crear / Editar + image_picker
└── widgets/
    ├── dashboard_card.dart            # Card reutilizable del Dashboard
    └── skeleton_list.dart             # Skeletons genéricos
```

### Separación de capas

| Capa | Responsabilidad |
|---|---|
| **models/** | Entidades de datos con serialización JSON |
| **services/** | Comunicación HTTP con Dio, manejo de excepciones |
| **isolates/** | Procesamiento en segundo plano con Isolate |
| **views/** | Pantallas y widgets específicos de UI |
| **widgets/** | Componentes reutilizables |
| **config/** | Configuración global (router, temas) |

---

## Rutas con GoRouter

| Ruta | Nombre | Pantalla | Parámetros |
|---|---|---|---|
| `/` | `home` | `HomeScreen` | — |
| `/estadisticas` | `estadisticas` | `EstadisticasScreen` | — |
| `/establecimientos` | `establecimientos` | `ListadoScreen` | — |
| `/establecimientos/crear` | `establecimiento-crear` | `FormularioScreen` | — |
| `/establecimientos/:id` | `establecimiento-detalle` | `DetalleScreen` | `id` (path) |
| `/establecimientos/:id/editar` | `establecimiento-editar` | `FormularioScreen` | `id` (path) |

### Paso de parámetros entre pantallas

```dart
// Navegar al detalle pasando el ID por path parameter
context.pushNamed(
  'establecimiento-detalle',
  pathParameters: {'id': establecimiento.id.toString()},
);

// Recibir el parámetro en el builder del GoRoute
GoRoute(
  path: ':id',
  builder: (context, state) {
    final id = int.parse(state.pathParameters['id']!);
    return DetalleScreen(establecimientoId: id);
  },
);
```

---

## Paquetes Utilizados

| Paquete | Versión | Uso |
|---|---|---|
| `dio` | ^5.8.0+1 | Cliente HTTP para ambas APIs |
| `go_router` | ^15.1.3 | Navegación declarativa con rutas nombradas |
| `flutter_dotenv` | ^5.2.1 | Variables de entorno (`.env`) |
| `fl_chart` | ^1.0.0 | PieChart y BarChart |
| `skeletonizer` | ^2.1.3 | Efecto skeleton durante carga |
| `image_picker` | ^1.1.2 | Selección de logo desde galería/cámara |

---

## Variables de Entorno (.env)

```env
ACCIDENTS_API_URL=https://www.datos.gov.co/resource/ezt8-5wyj.json
PARKING_API_URL=https://parking.visiontic.com.co/api
PARKING_LOGOS_URL=https://parking.visiontic.com.co/logos
```

---

## Capturas de Pantalla

### Dashboard
*(Captura del HomeScreen con resumen de totales y cards de navegación)*
[image](/ScreenShoot/dashboard.png)

### Estadísticas de Accidentes
*(4 capturas — una por cada gráfica: PieChart clase, PieChart gravedad, BarChart top 5 barrios, BarChart días)*
[image](/ScreenShoot/Estadistica1.jpg)
[image](/ScreenShoot/EstadisticaII.jpg)

### Listado de Establecimientos
*(Captura con Skeletonizer cargando + captura con datos cargados)*
[image](/ScreenShoot/skeleteon.png)
[image](/ScreenShoot/get.png)

### Formulario Crear
*(Captura del formulario vacío con selector de imagen)*
[image](/ScreenShoot/post.png)

### Formulario Editar
*(Captura del formulario precargado con datos del establecimiento)*
[image](/ScreenShoot/deleteANDupadte.png)

### Eliminación
*(Captura del diálogo de confirmación de eliminación)*
[image](/ScreenShoot/eliminar.jpg)

```
main ← dev ← feature/parcial_flutter_final
```

1. Se creó `feature/parcial_flutter_final` a partir de `dev`
2. Commits atómicos con convención: `feat:`, `fix:`, `docs:`, etc.
3. Pull Request `feature → dev` con descripción y evidencias
4. Merge a `dev` y luego a `main`
