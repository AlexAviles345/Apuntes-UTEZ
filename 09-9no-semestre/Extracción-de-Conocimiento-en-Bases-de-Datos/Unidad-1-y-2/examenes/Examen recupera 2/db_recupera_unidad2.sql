CREATE DATABASE recu_unidad2;
USE recu_unidad2;

CREATE TABLE PLATFORM(
	Id INT AUTO_INCREMENT PRIMARY KEY, 
    Name TEXT
);

CREATE TABLE GAME(
	Id INT AUTO_INCREMENT PRIMARY KEY, 
    IdPlatform INT, 
    Name TEXT, 
    Year INT, 
    Genre TEXT, 
    Publisher TEXT, 
    Global_Sales DECIMAL(10,2),
    
    FOREIGN KEY (IdPlatform) REFERENCES PLATFORM(Id)
);

