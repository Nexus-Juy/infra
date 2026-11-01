# Pruebas de LogiTrack en Apidog

Colección con **113 requests** organizadas por servicio, cada una con sus aserciones (códigos de estado, campos de
la respuesta y mensajes de error). Está en formato **Postman v2.1**, que Apidog importa directamente.

| Archivo | Para qué |
|---|---|
| `LogiTrack.postman_collection.json` | Las requests, ordenadas en carpetas, con sus pruebas |
| `LogiTrack-local.postman_environment.json` | El entorno `LogiTrack local`: URLs, credenciales de prueba y variables que las pruebas completan solas |

## Estructura de la colección

| Carpeta | Qué muestra |
|---|---|
| `00 - Infraestructura` | Health de los 4 servicios y la configuración que entrega el config-server |
| `01 - Preparacion` | Crea los usuarios de prueba (ADMIN, 2 CLIENTES, REPARTIDOR) y guarda sus tokens. **Correr primero** |
| `02 - security-service` | Registro, login (usuario o email), `/me`, validaciones y token inválido o alterado |
| `03 - courier-service` | Alta y consulta de repartidores, estado y **disponibilidad**, permisos por rol |
| `04 - shipment-service` | Ciclo de vida de un envío, historial, **asignación con OpenFeign**, permisos y errores |
| `05 - Cliente y pertenencia` | Cada cliente solo ve lo suyo; el repartidor solo lo asignado; el ADMIN todo |
| `06 - Escenario E2E` | Recorrido completo y autocontenido de punta a punta (ideal para el escenario de pruebas) |

## Importar en Apidog

1. **Levantá el sistema** (ver `README.md` de la raíz) y comprobá que los 7 contenedores estén `healthy`.
2. Creá un proyecto nuevo en Apidog (por ejemplo, `LogiTrack`).
3. **Importar la colección:** *Settings* (configuración del proyecto) → *Import Data* → *Postman* y subí
   `LogiTrack.postman_collection.json`.
4. **Importar el entorno:** en *Environment Management* elegí *Import Postman Environment* y subí
   `LogiTrack-local.postman_environment.json`. (También se puede desde *Import Data* → *Postman*.)
5. Seleccioná el entorno **LogiTrack local** arriba a la derecha. Sin entorno activo, los tokens no se guardan.

Los nombres exactos de los menús pueden variar según la versión de Apidog.

## Cómo ejecutar

- **Una request:** abrila y enviála. Las aserciones se muestran en la pestaña de resultados.
- **Una carpeta:** corrés la carpeta completa con el *Runner* o eligiéndola para ejecutar. Orden recomendado: `01`, `02`, `03`, `04`, `05`.
- **Escenario E2E (para mostrar):** en la sección de **Tests** creá un *Test Scenario* llamado `E2E completo` e
  importá como pasos las requests de la carpeta `06 - Escenario E2E`, en orden. Antes, ejecutá una vez la
  carpeta `01 - Preparacion` para que exista el usuario ADMIN. Después, el escenario puede correrse cuantas veces
  quieras: usa datos nuevos en cada corrida. Al terminar, Apidog genera un informe que se puede exportar o adjuntar al informe del proyecto.
- **No incluir en corridas automáticas:** la subcarpeta `Manual - courier-service caido` (dentro de `04`), porque
  necesita detener un servicio.

## Variables

Las URLs, las credenciales del ADMIN y los ids de los datos de ejemplo vienen en el entorno. Las pruebas guardan
automáticamente tokens e ids (con `pm.environment.set`). Si en tu versión de Apidog algún script no se importara,
se pueden recrear como *extracción de variables* en la request:

| Variable | Se extrae de | Request |
|---|---|---|
| `tokenAdmin`, `tokenClienteA`, `tokenClienteB`, `tokenRepartidor` | `$.token` | Logins de `01 - Preparacion` |
| `repartidorNuevoId` | `$.id` | Registrar un repartidor (`03`) |
| `envioId`, `codigo` | `$.id`, `$.codigoSeguimiento` | Registrar un envío (`04`) |
| `envioA`, `clienteIdA` | `$.id`, `$.clienteId` | A registra su envío (`05`) |
| `envioB` | `$.id` | B registra su envío (`05`) |

El script `tokenAlterado` (cambia un carácter de la firma del token) se ejecuta antes de las requests que lo usan.

## Documentación de la API (opcional)

Para tener la documentación de cada endpoint, además de las pruebas, Apidog puede importar el OpenAPI de los
servicios que lo publican (Swagger):

- `http://localhost:8081/v3/api-docs` (shipment-service)
- `http://localhost:8082/v3/api-docs` (courier-service)

`security-service` no publica OpenAPI; sus endpoints quedan documentados con la colección.

## Guion para la demostración

Una secuencia de unos 8 minutos, con qué mostrar y qué decir:

1. **Infraestructura (`00`):** los 4 servicios en `UP` y el config-server entregando la configuración de cada uno
   desde el repositorio `logitrack-config`. *"Toda la configuración está centralizada; los secretos son variables de entorno."*
2. **Seguridad (`02`):** registro y login. Mostrar que la respuesta trae un JWT. *"Las contraseñas se guardan con
   BCrypt y el token se firma con HMAC-SHA256 (HS256)."* Correr `/me con la firma alterada` → 401: si se modifica el
   token, la firma deja de coincidir.
3. **Permisos por rol (`03`):** un CLIENTE intentando crear un repartidor → 403.
4. **Comunicación entre servicios (`04`, asignación):** asignar un repartidor activo (200) y uno inactivo (422).
   *"shipment-service le pregunta la disponibilidad a courier-service con Spring Cloud OpenFeign."*
5. **Pertenencia (`05`):** el cliente B intentando ver el envío de A → 403.
6. **Escenario completo (`06`):** correr el escenario E2E y mostrar el informe: cliente, repartidor, envío, asignación,
   ruta, entrega e historial.
7. **Tolerancia a fallas (opcional):** detener courier (`docker compose stop courier-service`), correr la request
   de la carpeta `Manual` → 503 y no un 500; levantarlo de nuevo (`docker compose start courier-service`).

## Ejecutar desde la terminal (opcional)

Con Node instalado se puede correr la misma colección sin abrir Apidog:

```bash
npx newman run LogiTrack.postman_collection.json -e LogiTrack-local.postman_environment.json \
  --folder "01 - Preparacion (correr primero)" --folder "06 - Escenario E2E (demo completa)"
```

## Notas

- Los datos de ejemplo (Lucía, Martín, Sofía y los envíos de prueba) se cargan solo cuando se crea la base. Si ya
  se modificaron, `docker compose down -v` y volver a levantar los deja como al principio.
- Las pruebas crean usuarios y envíos nuevos en cada corrida (con un sufijo único); no hace falta limpiar nada.
- Los tokens y las credenciales de prueba son solo para entorno local. No subir al repositorio un entorno exportado con tokens reales.
