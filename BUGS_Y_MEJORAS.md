# Bugs y mejoras - GymVault

### Pantalla de ejercicio (rediseño)
**Campos adicionales (baja prioridad y poco protagonismo)**
- **RIR por serie (opcional):** campo opcional por repetición o por serie para indicar el RIR de esa serie. Puede quedar vacío.
- **Break time entre series (opcional):** tiempo de descanso entre series. Puede quedar vacío.
  - **Autocompletar:** este campo debe llenarse automáticamente si el usuario activa el cronómetro.
- **Campo de notas (opcional, desplegable):** campo de texto libre para notas generales del ejercicio. Debe ser colapsable para no ocupar espacio en pantalla. Ya existía antes — verificar si hay código/lógica previa y reactivarlo.

### Gráfico de peso (evolución de cargas)
- Al hacer tap en los puntos del gráfico, mostrar el **detalle del registro de ese día**.
- Es importante guardar **todos** los detalles del día para poder mostrarlos:
  - Peso
  - Repeticiones
  - Series
  - RIR
  - Timer / cronómetro

### Cronómetro y reloj
- El cronómetro debe estar por defecto en **3 minutos**.
- El reloj debe estar presente en la pantalla de **ejercicios personalizados**.
- Al hacer tap en la notificación del cronómetro, abrir la app con el **pop-up del cronómetro ya abierto**.

### Pop-up del cronómetro (UI)
- Crear una versión más chica del pop-up, o ajustar la existente para este caso:
  - Cuando el cronómetro está corriendo y se "cierra" o "minimiza" el pop-up, mostrar una **barra pequeña en la parte inferior** con el timer.
  - Al hacer tap en la barra, abrir nuevamente el pop-up grande.

### Nudges (recordatorios)
- Al agregar una serie, mostrar un indicador tipo "shining" que haga brillar el botón del cronómetro para recordar que se puede usar.

### Bugs
- **Crear ejercicio personalizado:** quitar el campo de subir foto al crear ejercicio (no es relevante).
- **Rutinas (sync):** no se están guardando los ejercicios en las rutinas. Al abrir la cuenta en otro dispositivo no se visualizan los ejercicios guardados en las rutinas: cargan las rutinas, muestra la cantidad de ejercicios, pero al entrar al detalle no aparecen.
- **Rutinas (agregar ejercicio):** al agregar ejercicios a una rutina a veces falla en el primer intento; si se vuelve a intentar funciona. Intermitente — posible race condition o error silencioso en el primer request.

### Pendiente por revisar (Jesús)
- Checar errores de Crashlytics.
