function showSection(name, el) {
  document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
  document.querySelectorAll('.nav-tab').forEach(t => t.classList.remove('active'));
  document.getElementById('s-' + name).classList.add('active');
  el.classList.add('active');
}

function toggleForm(id) {
  const f = document.getElementById(id);
  f.style.display = f.style.display === 'none' ? 'block' : 'none';
}

function confirmar(msg) {
  return confirm(msg);
}

function filtrarTabla(inputId, tablaId) {
  const query = document.getElementById(inputId).value.toLowerCase();
  const filas = document.getElementById(tablaId).querySelectorAll('tr');
  filas.forEach(fila => {
    fila.style.display = fila.textContent.toLowerCase().includes(query) ? '' : 'none';
  });
}

function editarCliente(id, cedula, nombre, apellido, email, telefono) {
  document.getElementById('edit-cliente-id').value      = id;
  document.getElementById('edit-cliente-cedula').value  = cedula;
  document.getElementById('edit-cliente-nombre').value  = nombre;
  document.getElementById('edit-cliente-apellido').value = apellido;
  document.getElementById('edit-cliente-email').value   = email;
  document.getElementById('edit-cliente-telefono').value = telefono;
  document.getElementById('form-cliente-edit').style.display = 'block';
  document.getElementById('form-cliente').style.display = 'none';
  document.getElementById('form-cliente-edit').scrollIntoView({ behavior: 'smooth' });
}

function editarClase(id, nombre, id_instructor, fecha, hora_inicio, hora_fin, capacidad, descripcion) {
  document.getElementById('edit-clase-id').value          = id;
  document.getElementById('edit-clase-nombre').value      = nombre;
  document.getElementById('edit-clase-instructor').value  = id_instructor;
  document.getElementById('edit-clase-fecha').value       = fecha;
  document.getElementById('edit-clase-hora-inicio').value = hora_inicio;
  document.getElementById('edit-clase-hora-fin').value    = hora_fin;
  document.getElementById('edit-clase-capacidad').value   = capacidad;
  document.getElementById('edit-clase-descripcion').value = descripcion;
  document.getElementById('form-clase-edit').style.display = 'block';
  document.getElementById('form-clase').style.display = 'none';
  document.getElementById('form-clase-edit').scrollIntoView({ behavior: 'smooth' });
}

function editarReserva(id, id_cliente, id_clase, estado) {
  document.getElementById('edit-reserva-id').value      = id;
  document.getElementById('edit-reserva-cliente').value = id_cliente;
  document.getElementById('edit-reserva-clase').value   = id_clase;
  document.getElementById('edit-reserva-estado').value  = estado;
  document.getElementById('form-reserva-edit').style.display = 'block';
  document.getElementById('form-reserva').style.display = 'none';
  document.getElementById('form-reserva-edit').scrollIntoView({ behavior: 'smooth' });
}

setTimeout(() => {
  document.querySelectorAll('.flash').forEach(f => {
    f.style.transition = 'opacity 0.5s';
    f.style.opacity = '0';
    setTimeout(() => f.remove(), 500);
  });
}, 3000);
