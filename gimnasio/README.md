# Gym.DB — Sistema de Reservas
## Instrucciones para correr la app

### 1. Instalar dependencias
```bash
pip install flask cx_Oracle
```

### 2. Configurar la conexión a Oracle
Abre `app.py` y edita estas 3 líneas con los datos del servidor del profesor:
```python
DB_USER     = "tu_usuario"
DB_PASSWORD = "tu_contrasena"
DB_DSN      = "localhost:1521/XEPDB1"
```

### 3. Correr la app
```bash
python app.py
```

### 4. Abrir en el navegador
```
http://localhost:5000
```

---

## Estructura del proyecto
```
gimnasio/
├── app.py              ← Backend Flask + conexión Oracle
├── templates/
│   └── index.html      ← Interfaz de usuario
├── static/
│   ├── style.css       ← Estilos dark mode
│   └── app.js          ← Lógica del frontend
└── README.md
```

## Seguridad implementada
- Sentencias preparadas en todas las operaciones (previene SQL Injection)
- COMMIT y ROLLBACK en cada transacción
- Manejo de errores con mensajes al usuario
