# Verificación manual del Sprint 3

Prueba de punta a punta con **todo el sistema en Docker** (issue S3-12). Completar la columna *Resultado* con
✔ o ✘ y una nota si algo falló.

- **Fecha:** ____ / ____ / ________
- **Quién la ejecutó:** ______________________
- **Versión de las imágenes (`IMAGE_TAG`):** ______________

## Preparación

```bash
cd infra
cp .env.example .env     # completar JWT_SECRET (mínimo 32 caracteres) y las claves de MySQL
docker compose down -v   # estado limpio
docker compose up -d
docker compose ps
```

## Checklist

| # | Qué hacer | Resultado esperado | Resultado |
|---|---|---|---|
| 1 | `docker compose ps` | Los **9 contenedores** (3 MySQL, config-server, eureka-server, security, courier, shipment y api-gateway) en `healthy`; el orden de arranque respeta config-server → eureka-server → servicios → api-gateway | |
| 2 | Abrir `http://localhost:8065` | El panel de Eureka lista `API-GATEWAY`, `COURIER-SERVICE`, `SECURITY-SERVICE` y `SHIPMENT-SERVICE` en `UP`, y **no** a `eureka-server` | |
| 3 | `http://localhost:8888/api-gateway/prod` y `/shipment-service/prod` | El config-server entrega la configuración; los secretos aparecen como `${VARIABLE}` | |
| 4 | `http://localhost:8081`, `:8082` y `:8083` | **No responden** desde el host (solo se entra por el gateway) | |
| 5 | `POST http://localhost:8066/api/v1/auth/login` con `admin.demo` | 200 con un JWT | |
| 6 | `GET http://localhost:8066/api/v1/envios` sin token | 401 `ProblemDetail`, título "No autorizado" | |
| 7 | La misma request con la firma del token alterada | 401 | |
| 8 | Como CLIENTE: `POST /api/v1/repartidores` | 403 "Acceso denegado" desde el gateway (`application/problem+json`) | |
| 9 | Como ADMIN: crear un repartidor | 201 | |
| 10 | Como CLIENTE: registrar un envío | 201, estado `PENDIENTE` | |
| 11 | Como ADMIN: asignar un repartidor activo al envío | 200 (shipment consulta a courier por OpenFeign) | |
| 12 | Asignar un repartidor inactivo (Sofía) | 422 | |
| 13 | Asignar un repartidor inexistente | 404 | |
| 14 | Cambiar el envío a `EN_RUTA` y a `ENTREGADO` | 200 en ambos; el historial muestra los cambios | |
| 15 | Otro CLIENTE intenta ver el envío | 403 (pertenencia, lo resuelve shipment-service) | |
| 15b | `OPTIONS /api/v1/envios` con `Origin: http://localhost:3000` y luego con un origen no permitido | Con el permitido, headers CORS y sin pedir token; con el otro, sin `Access-Control-Allow-Origin` | |
| 16 | `docker compose stop courier-service` y asignar un repartidor | **503** `ProblemDetail` (no 500) | |
| 17 | Repetir la asignación 5 o 6 veces | 503 cada vez; las últimas responden al instante (circuito abierto) | |
| 18 | `docker compose start courier-service`, esperar unos 10–60 s y asignar | 200: vuelve a funcionar sin reiniciar shipment-service | |
| 19 | Ejecutar en Apidog el escenario `06 - Escenario E2E` y la carpeta `07 - api-gateway` | Todas las aserciones pasan | |
| 20 | `docker compose logs` de los servicios | Sin errores inesperados ni stack traces | |

## Observaciones

_(anotar acá lo que falló, cómo se resolvió y en qué commit)_
