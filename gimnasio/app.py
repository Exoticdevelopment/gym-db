from flask import Flask, render_template, request, redirect, url_for, flash
import oracledb as cx_Oracle

app = Flask(__name__)
app.secret_key = "gymdb_secret_2026"

# ─── CONFIGURACIÓN DE CONEXIÓN ORACLE ────────────────────────────────────────
# Cambia estos datos según el servidor del profesor
DB_USER     = "tu_usuario"
DB_PASSWORD = "tu_contrasena"
DB_DSN      = "localhost:1521/XEPDB1"   # host:puerto/servicio

def get_connection():
    """Retorna una conexión a Oracle. Lanza excepción si falla."""
    return cx_Oracle.connect(
        user=DB_USER,
        password=DB_PASSWORD,
        dsn=DB_DSN
    )

# ─── RUTA PRINCIPAL ──────────────────────────────────────────────────────────
@app.route("/")
def index():
    try:
        conn = get_connection()
        cur  = conn.cursor()

        # Estadísticas para el dashboard
        cur.execute("SELECT COUNT(*) FROM CLIENTE")
        total_clientes = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM CLASE")
        total_clases = cur.fetchone()[0]

        cur.execute("SELECT COUNT(*) FROM RESERVA WHERE estado = 'ACTIVA'")
        total_reservas = cur.fetchone()[0]

        # Reservas recientes para el dashboard
        cur.execute("""
            SELECT r.id_reserva, cl.nombre, cl.apellido,
                   c.nombre, r.fecha_reserva, r.estado
            FROM RESERVA r
            JOIN CLIENTE cl ON cl.id_cliente = r.id_cliente
            JOIN CLASE   c  ON c.id_clase    = r.id_clase
            ORDER BY r.fecha_reserva DESC
            FETCH FIRST 10 ROWS ONLY
        """)
        reservas_recientes = [
            {
                "id_reserva":      row[0],
                "nombre_cliente":  row[1],
                "apellido_cliente": row[2],
                "nombre_clase":    row[3],
                "fecha_reserva":   row[4].strftime("%Y-%m-%d") if row[4] else "",
                "estado":          row[5],
            }
            for row in cur.fetchall()
        ]

        # Clientes
        cur.execute("""
            SELECT id_cliente, cedula, nombre, apellido,
                   email, telefono, fecha_registro
            FROM CLIENTE ORDER BY id_cliente
        """)
        clientes = [
            {
                "id_cliente":     row[0],
                "cedula":         row[1],
                "nombre":         row[2],
                "apellido":       row[3],
                "email":          row[4],
                "telefono":       row[5],
                "fecha_registro": row[6].strftime("%Y-%m-%d") if row[6] else "",
            }
            for row in cur.fetchall()
        ]

        # Instructores (para el select de clases)
        cur.execute("SELECT id_instructor, nombre, apellido FROM INSTRUCTOR ORDER BY nombre")
        instructores = [
            {"id_instructor": row[0], "nombre": row[1], "apellido": row[2]}
            for row in cur.fetchall()
        ]

        # Clases
        cur.execute("""
            SELECT c.id_clase, c.nombre, c.descripcion, c.fecha,
                   TO_CHAR(c.hora_inicio, 'HH24:MI'),
                   TO_CHAR(c.hora_fin,    'HH24:MI'),
                   c.capacidad_max, c.id_instructor,
                   i.nombre, i.apellido
            FROM CLASE c
            JOIN INSTRUCTOR i ON i.id_instructor = c.id_instructor
            ORDER BY c.fecha, c.hora_inicio
        """)
        clases = [
            {
                "id_clase":           row[0],
                "nombre":             row[1],
                "descripcion":        row[2],
                "fecha":              row[3].strftime("%Y-%m-%d") if row[3] else "",
                "hora_inicio":        row[4],
                "hora_fin":           row[5],
                "capacidad_max":      row[6],
                "id_instructor":      row[7],
                "nombre_instructor":  row[8],
                "apellido_instructor":row[9],
            }
            for row in cur.fetchall()
        ]

        # Reservas
        cur.execute("""
            SELECT r.id_reserva, cl.nombre, cl.apellido,
                   c.nombre, r.fecha_reserva, r.estado,
                   r.id_cliente, r.id_clase
            FROM RESERVA r
            JOIN CLIENTE cl ON cl.id_cliente = r.id_cliente
            JOIN CLASE   c  ON c.id_clase    = r.id_clase
            ORDER BY r.id_reserva DESC
        """)
        reservas = [
            {
                "id_reserva":       row[0],
                "nombre_cliente":   row[1],
                "apellido_cliente": row[2],
                "nombre_clase":     row[3],
                "fecha_reserva":    row[4].strftime("%Y-%m-%d") if row[4] else "",
                "estado":           row[5],
                "id_cliente":       row[6],
                "id_clase":         row[7],
            }
            for row in cur.fetchall()
        ]

        cur.close()
        conn.close()
    except Exception as e:
        flash(f"Error de conexión a BD: {e}. Mostrando interfaz sin datos.", "error")
        total_clientes = 0
        total_clases = 0
        total_reservas = 0
        reservas_recientes = []
        clientes = []
        instructores = []
        clases = []
        reservas = []

    return render_template(
        "index.html",
        stats={
            "clientes": total_clientes,
            "clases":   total_clases,
            "reservas": total_reservas,
        },
        reservas_recientes=reservas_recientes,
        clientes=clientes,
        instructores=instructores,
        clases=clases,
        reservas=reservas,
    )


# ─── CLIENTES ────────────────────────────────────────────────────────────────
@app.route("/clientes/crear", methods=["POST"])
def crear_cliente():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        # Sentencia preparada — previene SQL Injection
        cur.execute("""
            INSERT INTO CLIENTE (cedula, nombre, apellido, email, telefono, fecha_registro)
            VALUES (:1, :2, :3, :4, :5, SYSDATE)
        """, (
            request.form["cedula"],
            request.form["nombre"],
            request.form["apellido"],
            request.form["email"],
            request.form.get("telefono") or None,
        ))
        conn.commit()
        flash("Cliente registrado correctamente.", "success")
    except cx_Oracle.IntegrityError:
        conn.rollback()
        flash("Error: la cédula o email ya está registrado.", "error")
    except Exception as e:
        conn.rollback()
        flash(f"Error al registrar cliente: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


@app.route("/clientes/editar", methods=["POST"])
def editar_cliente():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        cur.execute("""
            UPDATE CLIENTE
            SET cedula=:1, nombre=:2, apellido=:3, email=:4, telefono=:5
            WHERE id_cliente=:6
        """, (
            request.form["cedula"],
            request.form["nombre"],
            request.form["apellido"],
            request.form["email"],
            request.form.get("telefono") or None,
            request.form["id_cliente"],
        ))
        conn.commit()
        flash("Cliente actualizado correctamente.", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al actualizar cliente: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


@app.route("/clientes/eliminar", methods=["POST"])
def eliminar_cliente():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        cur.execute("DELETE FROM CLIENTE WHERE id_cliente = :1",
                    (request.form["id_cliente"],))
        conn.commit()
        flash("Cliente eliminado correctamente.", "success")
    except cx_Oracle.IntegrityError:
        conn.rollback()
        flash("No se puede eliminar: el cliente tiene reservas activas.", "error")
    except Exception as e:
        conn.rollback()
        flash(f"Error al eliminar cliente: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


# ─── CLASES ──────────────────────────────────────────────────────────────────
@app.route("/clases/crear", methods=["POST"])
def crear_clase():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO CLASE (nombre, descripcion, fecha, hora_inicio, hora_fin, capacidad_max, id_instructor)
            VALUES (:1, :2, TO_DATE(:3,'YYYY-MM-DD'),
                    TO_TIMESTAMP(:4,'HH24:MI'),
                    TO_TIMESTAMP(:5,'HH24:MI'),
                    :6, :7)
        """, (
            request.form["nombre"],
            request.form.get("descripcion") or None,
            request.form["fecha"],
            request.form["hora_inicio"],
            request.form["hora_fin"],
            int(request.form["capacidad_max"]),
            int(request.form["id_instructor"]),
        ))
        conn.commit()
        flash("Clase registrada correctamente.", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al registrar clase: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


@app.route("/clases/editar", methods=["POST"])
def editar_clase():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        cur.execute("""
            UPDATE CLASE
            SET nombre=:1, descripcion=:2,
                fecha=TO_DATE(:3,'YYYY-MM-DD'),
                hora_inicio=TO_TIMESTAMP(:4,'HH24:MI'),
                hora_fin=TO_TIMESTAMP(:5,'HH24:MI'),
                capacidad_max=:6, id_instructor=:7
            WHERE id_clase=:8
        """, (
            request.form["nombre"],
            request.form.get("descripcion") or None,
            request.form["fecha"],
            request.form["hora_inicio"],
            request.form["hora_fin"],
            int(request.form["capacidad_max"]),
            int(request.form["id_instructor"]),
            int(request.form["id_clase"]),
        ))
        conn.commit()
        flash("Clase actualizada correctamente.", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al actualizar clase: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


@app.route("/clases/eliminar", methods=["POST"])
def eliminar_clase():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        cur.execute("DELETE FROM CLASE WHERE id_clase = :1",
                    (int(request.form["id_clase"]),))
        conn.commit()
        flash("Clase eliminada correctamente.", "success")
    except cx_Oracle.IntegrityError:
        conn.rollback()
        flash("No se puede eliminar: la clase tiene reservas asociadas.", "error")
    except Exception as e:
        conn.rollback()
        flash(f"Error al eliminar clase: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


# ─── RESERVAS ────────────────────────────────────────────────────────────────
@app.route("/reservas/crear", methods=["POST"])
def crear_reserva():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        cur.execute("""
            INSERT INTO RESERVA (fecha_reserva, estado, id_cliente, id_clase)
            VALUES (SYSDATE, :1, :2, :3)
        """, (
            request.form["estado"],
            int(request.form["id_cliente"]),
            int(request.form["id_clase"]),
        ))
        conn.commit()
        flash("Reserva registrada correctamente.", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al registrar reserva: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


@app.route("/reservas/editar", methods=["POST"])
def editar_reserva():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        cur.execute("""
            UPDATE RESERVA
            SET id_cliente=:1, id_clase=:2, estado=:3
            WHERE id_reserva=:4
        """, (
            int(request.form["id_cliente"]),
            int(request.form["id_clase"]),
            request.form["estado"],
            int(request.form["id_reserva"]),
        ))
        conn.commit()
        flash("Reserva actualizada correctamente.", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al actualizar reserva: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


@app.route("/reservas/eliminar", methods=["POST"])
def eliminar_reserva():
    conn = get_connection()
    cur  = conn.cursor()
    try:
        cur.execute("DELETE FROM RESERVA WHERE id_reserva = :1",
                    (int(request.form["id_reserva"]),))
        conn.commit()
        flash("Reserva eliminada correctamente.", "success")
    except Exception as e:
        conn.rollback()
        flash(f"Error al eliminar reserva: {str(e)}", "error")
    finally:
        cur.close()
        conn.close()
    return redirect(url_for("index"))


# ─── ARRANQUE ────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    app.run(debug=True, port=5000)
