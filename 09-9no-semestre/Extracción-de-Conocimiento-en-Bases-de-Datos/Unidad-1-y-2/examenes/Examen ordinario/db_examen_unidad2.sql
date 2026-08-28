CREATE DATABASE ordinario_u2;
USE ordinario_u2;

CREATE TABLE pasajeros_titanic (
	id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    sexo VARCHAR(10),
    edad INT,
    tipo_pasajero INT,
    sobrevivio TINYINT
);

SELECT * FROM pasajeros_titanic;