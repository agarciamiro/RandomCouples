# RandomCouples (iOS) — v3.0

App iOS (SwiftUI) para armar equipos y orden de juego **random** (2, 4, 6 u 8 jugadores), asignar **PAR/IMPAR** y llevar **puntajes** por equipo y por jugador.

## ✅ Funcionalidades

- Soporta **2, 4, 6 y 8 jugadores**.
- Genera equipos random:
  - 2 jugadores → 2 equipos de 1
  - 4 jugadores → 2 equipos de 2
  - 6 jugadores → 2 equipos de 3
  - 8 jugadores → **2 equipos de 4**
- Asignación **PAR / IMPAR** por equipo (random).
- Genera el **orden de juego alternado** entre PAR e IMPAR:
  - El **primer turno** es random (PAR o IMPAR)
  - Luego alterna (PAR/IMPAR/PAR/IMPAR…)
- Vista “Asignación”:
  - Muestra equipos con diseño tipo “card”
  - Muestra **Puntaje Acumulado** por equipo
  - Muestra jugadores del equipo ordenados **ascendente** por su número global
  - Para 8 jugadores, el **Orden de Juego** se muestra en **2 columnas (1–4 / 5–8)**
- Vista “Puntajes”:
  - Puntaje **individual** y **total** por equipo
  - Puntajes con límites **-99 a +99**
  - Puntajes **persisten** al volver atrás (`@Binding`)

## 🧭 Flujo de la app

1. Ingresar nombres (2/4/6/8)
2. Ruleta PAR/IMPAR + creación de equipos
3. Pantalla Asignación (equipos + orden de juego)
4. Agregar Puntajes (puntaje individual + total)

## 🛠 Requisitos

- macOS + Xcode (SwiftUI)
- iOS Simulator o dispositivo iPhone

## ▶️ Cómo correr

1. Abrir `RandomCouples.xcodeproj` en Xcode
2. Elegir simulador/dispositivo
3. Run (⌘R)

## 📌 Control de versiones

- Repo en GitHub: `agarciamiro/RandomCouples`
- Tag estable: **v3.0**

## 🗺 Roadmap (ideas)

- Botón “Nueva Partida / Reset Puntajes”
- Historial de partidas
- Exportar resultados (texto / PDF)
- Mejoras visuales / animaciones

## 👤 Autor

by **AGMP**


- v3.0.6 (2025-12-15): README actualizado (notas y estado del proyecto)
