create or replace PACKAGE PA_ESTUDIANTES AS 

TYPE TT_CLASES IS TABLE OF CLASSES%ROWTYPE INDEX BY BINARY_INTEGER; 
T_CLASES_SEC TT_CLASES;

 PROCEDURE PR_ALTA_ESTUDIANTE (P_NOMBRE STUDENTS.FIRST_NAME%TYPE, 
                                  P_APELLIDO STUDENTS.LAST_NAME%TYPE, 
                                  P_CARRERA STUDENTS.MAJOR%TYPE);
                                  
 PROCEDURE PR_ANOTAR_ESTUDIANTE (P_ID STUDENTS.ID%TYPE, 
                                   P_DEPARTAMENTO CLASSES.DEPARTMENT%TYPE, 
                                   P_CURSO CLASSES.COURSE%TYPE);

 PROCEDURE PR_ANOTAR_ESTUDIANTE (P_NOMBRE STUDENTS.FIRST_NAME%TYPE, 
                                   P_APELLIDO STUDENTS.LAST_NAME%TYPE,  
                                   P_DEPARTAMENTO CLASSES.DEPARTMENT%TYPE, 
                                   P_CURSO CLASSES.COURSE%TYPE);

 PROCEDURE PR_INGRESAR_NOTA (P_ID STUDENTS.ID%TYPE, 
                              P_DEPARTAMENTO CLASSES.DEPARTMENT%TYPE,
                              P_CURSO CLASSES.COURSE%TYPE,  
                              P_NOTA REGISTERED_STUDENTS.GRADE%TYPE);
                              
PROCEDURE PR_INGRESAR_NOTA (P_NOMBRE STUDENTS.FIRST_NAME%TYPE, 
                              P_APELLIDO STUDENTS.LAST_NAME%TYPE, 
                              P_DEPARTAMENTO CLASSES.DEPARTMENT%TYPE,
                              P_CURSO CLASSES.COURSE%TYPE,  
                              P_NOTA REGISTERED_STUDENTS.GRADE%TYPE);
                              
PROCEDURE PR_MOSTRAR_ALUMNOS (P_ID_CLASE CLASSES.COURSE%TYPE,  
                                    P_FLAG BOOLEAN);
                                    
PROCEDURE PR_MOSTRAR_ALUMNOS;
                              
                              
                              
END PA_ESTUDIANTES;