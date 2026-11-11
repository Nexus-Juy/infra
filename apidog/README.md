# Pruebas de LogiTrack en Apidog

Colección con **135 requests** organizadas por servicio y por tema, cada una con sus aserciones (códigos de estado,
campos de la respuesta y mensajes de error). Está en formato **Postman v2.1**, que Apidog importa directamente.

**Desde el Sprint 3, todo entra por el api-gateway (`http://localhost:8066`).** Los servicios de negocio ya no
publican puertos en el host: solo el gateway (8066), Eureka (8065) y el config-server (8888).

| Archivo | Para qué |
|---|---|
| `LogiTrack.postman_collection.json` | Las requests, ordenadas en carpetas, con sus pruebas |
| `LogiTrack-local.postman_environment.json` | El entorno `LogiTrack local`: URLs, credenciales de prueba y variables que las pruebas completan solas |

## Estructura de la colección

| Carpeta | Qué muestra |
|---|---|
| `00 - Infraestructura` | Health de config-server, eureka-server y api-gateway; **los 4 servicios registrados en Eureka** (`UP`); configuración que entrega el config-server a cada servicio |
| `01 - Preparacion` | Login del ADMIN y del REPARTIDOR de demo, registro de 2 CLIENTES, y guarda sus tokens. **Correr primero** |
| `02 - security-service` | Registro, login (usuario o email), `/me`, validaciones y token inválido o alterado |
| `03 - courier-service` | Alta y consulta de repartidores, estado y **disponibilidad**, permisos por rol |
| `04 - shipment-service` | Ciclo de vida de un envío, historial, **asignación con OpenFeign**, permisos y errores |
| `05 - Cliente y pertenencia` | Cada cliente solo ve lo suyo; el repartidor solo lo asignado; el ADMIN todo |
| `06 - Escenario E2E` | Recorrido completo y autocontenido de punta a punta (ideal para el escenario de pruebas) |
| `07 - api-gateway` | Rutas públicas, cada ruta hacia su servicio, **filtro JWT (401)**, rutas inexistentes (404), **autorización por roles (403)** y CORS |

## Importar en Apidog

1. **Levantá el sistema** (ver `README.md` de la raíz) y comprobá que todos los contenedores estén `healthy`.
2. Creá un proyecto nuevo en Apidog (por ejemplo, `LogiTrack`).
3. **Importar la colección:** *Settings* del proyecto → *Import Data* → *Postman* y subí
   `LogiTrack.postman_collection.json`.
4. **Importar el entorno:** en *Environment Management* elegí *Import Postman Environment* y subí
   `LogiTrack-local.postman_environment.json`.
5. Seleccioná el entorno **LogiTrack local** arriba a la derecha. Sin entorno activo, los tokens no se guardan.

Si ya tenías la colección del Sprint 2 importada, borrala e importá esta: cambiaron las URLs (ahora apuntan al
gateway) y se agregaron carpetas. Los nombres exactos de los menús pueden variar según la versión de Apidog.

## Cómo ejecutar

- **Una request:** abrila y enviála. Las aserciones se muestran en la pestaña de resultados.
- **Una carpeta:** corrés la carpeta completa con el *Runner*. Orden recomendado: `00`, `01`, `02`, `03`, `04`, `05`, `07`.
- **Escenario E2E (para mostrar):** en la sección de **Tests** creá un *Test Scenario* llamado `E2E completo` e
  importá como pasos las requests de `06 - Escenario E2E`, en orden. Antes, ejecutá una vez `01 - Preparacion`.
  Puede correrse cuantas veces quieras: usa datos nuevos en cada corrida.
- **No incluir en corridas automáticas:** la subcarpeta `Manual - courier-service caido` (dentro de `04`), porque
  necesita detener un servicio.
- **CORS:** la subcarpeta `CORS` de `07` usa la variable `cors_origin` (`http://localhost:3000`), que es uno de los
  orígenes permitidos en `api-gateway.yml`. Si cambiás `CORS_ALLOWED_ORIGINS`, actualizala.

## Variables

Las URLs, las credenciales del ADMIN y los ids de los datos de ejemplo vienen en el entorno.

| Variable | Valor | Para qué |
|---|---|---|
| `gateway_url` | `http://localhost:8066` | Punto de entrada |
| `security_url`, `courier_url`, `shipment_url` | `http://localhost:8066` | Apuntan al gateway: este enruta a cada servicio |
| `eureka_url` | `http://localhost:8065` | Panel y API de Eureka |
| `config_url` | `http://localhost:8888` | Config-server |
| `admin_username`, `admin_password` | `gw.admin` / `gateway123` | Usuario ADMIN de demo (lo crea security-service al arrancar, S4-14). La misma contraseña sirve para `gw.repartidor` |
| `cors_origin` | `http://localhost:3000` | Origen para las pruebas de CORS |

Las pruebas guardan tokens e ids con `pm.environment.set`. Si en tu versión de Apidog algún script no se importara,
se pueden recrear como *extracción de variables*:

| Variable | Se extrae de | Request |
|---|---|---|
| `tokenAdmin`, `tokenClienteA`, `tokenClienteB`, `tokenRepartidor` | `$.token` | Logins de `01 - Preparacion` |
| `repartidorNuevoId` | `$.id` | Registrar un repartidor (`03`) |
| `envioId`, `codigo` | `$.id`, `$.codigoSeguimiento` | Registrar un envío (`04`) |
| `envioA`, `clienteIdA` | `$.id`, `$.clienteId` | A registra su envío (`05`) |
| `envioB` | `$.id` | B registra su envío (`05`) |

El script `tokenAlterado` (cambia un carácter de la firma del token) se ejecuta antes de las requests que lo usan.

## Documentación de la API (opcional)

Los servicios que publican OpenAPI (Swagger) se pueden importar en Apidog. Como ya no se publican en el host, hay que
levantarlos desde el IDE (perfil `dev`) o entrar a su puerto interno:

- `shipment-service`: `/v3/api-docs`
- `courier-service`: `/v3/api-docs`

`security-service` no publica OpenAPI; sus endpoints quedan documentados con la colección.

## Guion para la demostración

Unos 10 minutos, con qué mostrar y qué decir:

1. **Infraestructura (`00`):** health de config-server, Eureka y gateway, y el request de Eureka con los 4 servicios
   `UP`. Abrir también el panel `http://localhost:8065`. *"Los servicios se registran solos al arrancar y se
   encuentran por su nombre lógico, sin IP ni puerto."*
2. **Punto único de entrada (`07`, rutas):** login por el gateway y una request a cada ruta. *"El gateway resuelve
   `lb://SECURITY-SERVICE`, `COURIER-SERVICE` y `SHIPMENT-SERVICE` en Eureka. Los servicios ya no son accesibles
   desde afuera."* Mostrar que `http://localhost:8081` no responde.
3. **Seguridad en el borde (`07`):** sin token → 401; token alterado → 401 (HMAC-SHA256: la firma ya no coincide);
   CLIENTE intentando crear un repartidor → 403 desde el gateway.
4. **Seguridad de los servicios (`02`):** login y registro. *"Contraseñas con BCrypt; el token se firma con HS256."*
5. **Comunicación entre servicios (`04`, asignación):** asignar un repartidor activo (200) y uno inactivo (422).
   *"shipment-service le pregunta la disponibilidad a courier-service con OpenFeign, resolviéndolo por Eureka."*
6. **Pertenencia (`05`):** el cliente B intentando ver el envío de A → 403.
7. **Escenario completo (`06`):** correr el escenario E2E y mostrar el informe.
8. **Tolerancia a fallas:** detener courier (`docker compose stop courier-service`), correr la request de la
   carpeta `Manual` → **503** y no un 500 (ErrorDecoder + fallback + circuit breaker). Repetirla varias veces: el
   circuito se abre y responde al instante. Levantarlo (`docker compose start courier-service`): pasados unos
   10 segundos, la asignación vuelve a funcionar sin reiniciar nada.

## Ejecutar desde la terminal (opcional)

Con Node instalado se puede correr la misma colección sin abrir Apidog:

```bash
npx newman run LogiTrack.postman_collection.json -e LogiTrack-local.postman_environment.json \
  --folder "01 - Preparacion (correr primero)" --folder "07 - api-gateway (8066)"
```

## Notas

- Los datos de ejemplo (Brian Abalos, Martín, Sofía y los envíos de prueba) se cargan solo cuando se crea la base. Si ya
  se modificaron, `docker compose down -v` y volver a levantar los deja como al principio.
- Las pruebas crean usuarios y envíos nuevos en cada corrida (con un sufijo único); no hace falta limpiar nada.
- Los tokens y las credenciales de prueba son solo para entorno local. No subir al repositorio un entorno exportado
  con tokens reales.
