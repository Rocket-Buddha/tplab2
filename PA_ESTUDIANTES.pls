create or replace PACKAGE BODY PA_ESTUDIANTES AS 
----------------------------------------------------------------------------------------------------------------------- 
/* ZONA DE DEFINICION DE EXCEPCIONES NATIVAS ORACLE */  
   
   E_FKP EXCEPTION; 
   PRAGMA EXCEPTION_INIT(E_FKP, -2290); 
    
   E_FKH EXCEPTION; 
   PRAGMA EXCEPTION_INIT(E_FKH, -2291); 
   
   E_PK EXCEPTION; 
   PRAGMA EXCEPTION_INIT(E_PK, -00001); 
-----------------------------------------------------------------------------------------------------------------------    
   /* ZONA DE DEFINICION DE EXCEPCIONES PROPIAS */ 
   
   E_MAX_CLASE EXCEPTION;
   PRAGMA EXCEPTION_INIT(E_MAX_CLASE, -20004);
   
   E_EST_ID EXCEPTION;
   PRAGMA EXCEPTION_INIT(E_EST_ID, -20003);
   
   E_CURSO_ID EXCEPTION;
   PRAGMA EXCEPTION_INIT(E_CURSO_ID, -20002);
   
   E_APROBO_MAT EXCEPTION;
   PRAGMA EXCEPTION_INIT(E_APROBO_MAT, -20001);
----------------------------------------------------------------------------------------------------------------------- 
   /* ZONA DE DEFINICION DE TABLAS */ 
   TYPE TR_ESTUDIANTE IS RECORD(FIRST_NAME STUDENTS.FIRST_NAME%TYPE, 
                                LAST_NAME STUDENTS.LAST_NAME%TYPE, 
                                MAJOR STUDENTS.MAJOR%TYPE, 
                                CURRENT_CREDITS STUDENTS.CURRENT_CREDITS%TYPE); 
                                 
    
   TYPE TT_ESTUDIANTES IS TABLE OF TR_ESTUDIANTE INDEX BY BINARY_INTEGER;    
   T_ESTUDIANTES TT_ESTUDIANTES; -- INDEXADA POR EL INDICE POR QUE FACILITA EL MANEJO 

----------------------------------------------------------------------------------------------------------------------- 
   /* ZONA DE DEFINICION DE CURSORES */ 
   CURSOR C_ESTUDIANTE IS SELECT * FROM STUDENTS; 
 
-----------------------------------------------------------------------------------------------------------------------   
   /* ZONA DE DEFINICION DE FUNCIONES */ 
    FUNCTION FU_OBTENER_ID(P_NOMBRE STUDENTS.FIRST_NAME%TYPE,
                            P_APELLIDO STUDENTS.LAST_NAME%TYPE) 
                            RETURN STUDENTS.ID%TYPE 
                            IS 
        
      L_ID STUDENTS.ID%TYPE;
      L_INDICE BINARY_INTEGER;
      
      BEGIN
    
        L_INDICE := T_ESTUDIANTES.FIRST;
        FOR J IN 1.. T_ESTUDIANTES.COUNT LOOP
         
        IF T_ESTUDIANTES(L_INDICE).FIRST_NAME = INITCAP(P_NOMBRE) AND T_ESTUDIANTES(L_INDICE).LAST_NAME = INITCAP(P_APELLIDO) THEN 
          RETURN L_INDICE; 
          ELSE L_INDICE:= T_ESTUDIANTES.NEXT(L_INDICE);
        END IF;
        
        END LOOP;
          RAISE_APPLICATION_ERROR(-20003, 'EL ESTUDIANTE NO EXISTE');      
         
    END FU_OBTENER_ID;
    
    --FUNCION PARA VALIDAR LA EXISTENCIA DE UNA CLASE
    FUNCTION FU_CLASE_EXISTE (P_ID_CLASE CLASSES.COURSE%TYPE) RETURN BOOLEAN IS
      
      R_INDICE BINARY_INTEGER;
      
      BEGIN
        
        R_INDICE := T_CLASES_SEC.FIRST;
        
        FOR i IN 1..T_CLASES_SEC.COUNT LOOP  
          IF T_CLASES_SEC(R_INDICE).COURSE = P_ID_CLASE THEN
            RETURN TRUE;
          END IF;
          R_INDICE := T_CLASES_SEC.NEXT(R_INDICE);
        END LOOP;
        
        RETURN FALSE;
        
    END FU_CLASE_EXISTE;
  
-----------------------------------------------------------------------------------------------------------------------   
   /* ZONA DE DEFINICION DE PROCEDURES */ 
    
    PROCEDURE PR_ALTA_ESTUDIANTE (P_NOMBRE STUDENTS.FIRST_NAME%TYPE, 
                                  P_APELLIDO STUDENTS.LAST_NAME%TYPE, 
                                  P_CARRERA STUDENTS.MAJOR%TYPE) 
                                  IS 
     
      L_MAX_ESTUDIANTE BINARY_INTEGER; 
      L_CARRERA MAJOR_STATS.MAJOR%TYPE; 
      
      BEGIN  
     
            L_MAX_ESTUDIANTE := NVL(T_ESTUDIANTES.LAST,0)+1; 
  
            INSERT INTO STUDENTS(ID, FIRST_NAME, LAST_NAME, MAJOR, CURRENT_CREDITS) 
            VALUES(L_MAX_ESTUDIANTE, INITCAP(P_NOMBRE), INITCAP(P_APELLIDO), INITCAP(P_CARRERA), 0);
            
            T_ESTUDIANTES(L_MAX_ESTUDIANTE).FIRST_NAME:= INITCAP(P_NOMBRE); 
            T_ESTUDIANTES(L_MAX_ESTUDIANTE).LAST_NAME := INITCAP(P_APELLIDO); 
            T_ESTUDIANTES(L_MAX_ESTUDIANTE).MAJOR:= INITCAP(P_CARRERA); 
            T_ESTUDIANTES(L_MAX_ESTUDIANTE).CURRENT_CREDITS:= 0;
            
           IF SQL%ROWCOUNT = 1 THEN  
            DBMS_OUTPUT.PUT_LINE('SE HA INSERTADO CORRECTAMENTE');
           END IF;
          
     EXCEPTION
     
      WHEN E_FKH THEN
        DBMS_OUTPUT.PUT_LINE('LA CARRERA NO EXISTE');
        
       WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Codigo de error: ' || SQLCODE || ': ' || SQLERRM);
   
   END PR_ALTA_ESTUDIANTE; 
 
   PROCEDURE PR_ANOTAR_ESTUDIANTE (P_ID STUDENTS.ID%TYPE, 
                                   P_DEPARTAMENTO CLASSES.DEPARTMENT%TYPE, 
                                   P_CURSO CLASSES.COURSE%TYPE) IS 
    
    L_ID STUDENTS.ID%TYPE;
    L_CUENTA_ESTUDIANTES CLASSES.MAX_STUDENTS%TYPE;
    L_MAX_ESTUDIANTES CLASSES.MAX_STUDENTS%TYPE;
    
    BEGIN 
      
      IF T_ESTUDIANTES.EXISTS(P_ID) THEN
        
        SELECT MAX(STUDENT_ID)
        INTO L_ID
        FROM REGISTERED_HISTORY
        WHERE STUDENT_ID = P_ID AND DEPARTMENT = UPPER(P_DEPARTAMENTO) AND (GRADE = 'A' OR GRADE ='B' OR GRADE = 'C');
        
        IF L_ID IS NOT NULL THEN
          RAISE_APPLICATION_ERROR(-20001, 'EL ALUMNO YA APROBO LA MATERIA');
        END IF;
        
        SELECT COUNT(STUDENT_ID)
        INTO L_CUENTA_ESTUDIANTES
        FROM REGISTERED_STUDENTS
        WHERE DEPARTMENT = UPPER(P_DEPARTAMENTO) AND COURSE=P_CURSO;
        
        L_MAX_ESTUDIANTES:=0;
        
        FOR i IN 1..T_CLASES_SEC.COUNT LOOP -- NO HACE FALTA USAR T_CLASES_SEC.FIRST YA QUE LA PRIMERA POSICION A SER SECUENCIAL ES 1
          
          IF T_CLASES_SEC(i).DEPARTMENT = UPPER(P_DEPARTAMENTO) AND T_CLASES_SEC(i).COURSE = P_CURSO THEN
          
           L_MAX_ESTUDIANTES:= T_CLASES_SEC(i).MAX_STUDENTS;
           EXIT; --CORTA EL LOOP
          
          END IF;
        
        END LOOP;
        
         IF L_CUENTA_ESTUDIANTES > L_MAX_ESTUDIANTES THEN
           RAISE_APPLICATION_ERROR(-20004, 'SE HA LLEGADO AL LIMITE MAXIMO DE ALUMNOS PARA ESA CLASE');
         END IF;
             
          INSERT INTO REGISTERED_STUDENTS (STUDENT_ID,DEPARTMENT,COURSE) 
          VALUES (P_ID,UPPER(P_DEPARTAMENTO),P_CURSO); 
        
      ELSE
        RAISE_APPLICATION_ERROR(-20003, 'EL ESTUDIANTE NO EXISTE');
      END IF;
      
      IF SQL%ROWCOUNT = 1 THEN  
            DBMS_OUTPUT.PUT_LINE('SE HA INSERTADO CORRECTAMENTE');
      END IF;
      
    EXCEPTION
    
      WHEN E_PK THEN 
        DBMS_OUTPUT.PUT_LINE('EL ALUMNO YA ESTA ANOTADO EN LA MATERIA'); 
        
      WHEN E_FKH THEN --ATRAPA PARENT KEY CONSTRAINT
        DBMS_OUTPUT.PUT_LINE('DEPARTAMENTO O CURSO NO EXISTE');
        
      WHEN E_MAX_CLASE THEN
        DBMS_OUTPUT.PUT_LINE('SE HA LLEGADO AL LIMITE MAXIMO DE ALUMNOS PARA ESA CLASE');
        
      WHEN E_EST_ID THEN
        DBMS_OUTPUT.PUT_LINE('EL ESTUDIANTE NO EXISTE');
        
      WHEN E_APROBO_MAT THEN
        DBMS_OUTPUT.PUT_LINE('EL ALUMNO YA APROBO LA MATERIA');
        
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Codigo de error: ' || SQLCODE || ': ' || SQLERRM);
        
   END PR_ANOTAR_ESTUDIANTE; 
    
   PROCEDURE PR_ANOTAR_ESTUDIANTE (P_NOMBRE STUDENTS.FIRST_NAME%TYPE, 
                                   P_APELLIDO STUDENTS.LAST_NAME%TYPE,  
                                   P_DEPARTAMENTO CLASSES.DEPARTMENT%TYPE, 
                                   P_CURSO CLASSES.COURSE%TYPE) IS 
    
      L_ID STUDENTS.ID%TYPE;
      
      BEGIN 
       
        L_ID := FU_OBTENER_ID(P_NOMBRE, P_APELLIDO);
        DBMS_OUTPUT.PUT_LINE(L_ID);
        
        PR_ANOTAR_ESTUDIANTE(L_ID,P_DEPARTAMENTO,P_CURSO);
      
      EXCEPTION
        
        WHEN E_EST_ID THEN
          DBMS_OUTPUT.PUT_LINE('EL ALUMNO NO EXISTE');
          
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Codigo de error: ' || SQLCODE || ': ' || SQLERRM);
          
    END PR_ANOTAR_ESTUDIANTE; 
    
  PROCEDURE PR_INGRESAR_NOTA (P_ID STUDENTS.ID%TYPE, 
                              P_DEPARTAMENTO CLASSES.DEPARTMENT%TYPE,
                              P_CURSO CLASSES.COURSE%TYPE,  
                              P_NOTA REGISTERED_STUDENTS.GRADE%TYPE) 
  IS 
     
    BEGIN 
    
    
      IF T_ESTUDIANTES.EXISTS(P_ID) THEN 
      
        UPDATE REGISTERED_STUDENTS 
        SET GRADE = P_NOTA
        WHERE STUDENT_ID = P_ID AND DEPARTMENT = P_DEPARTAMENTO AND COURSE = P_CURSO; 
    
      ELSE
        
        RAISE_APPLICATION_ERROR(-20003, 'EL ESTUDIANTE NO EXISTE');
        
      END IF;
      
    EXCEPTION
      
      WHEN E_EST_ID THEN
        DBMS_OUTPUT.PUT_LINE('EL ESTUDIANTE NO EXISTE');
        
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Codigo de error: ' || SQLCODE || ': ' || SQLERRM);
           
    END PR_INGRESAR_NOTA; 
    
  PROCEDURE PR_INGRESAR_NOTA (P_NOMBRE STUDENTS.FIRST_NAME%TYPE, 
                              P_APELLIDO STUDENTS.LAST_NAME%TYPE, 
                              P_DEPARTAMENTO CLASSES.DEPARTMENT%TYPE,
                              P_CURSO CLASSES.COURSE%TYPE,  
                              P_NOTA REGISTERED_STUDENTS.GRADE%TYPE) IS 
    L_ID STUDENTS.ID%TYPE;
     
    BEGIN 
     
      L_ID := FU_OBTENER_ID(P_NOMBRE, P_APELLIDO);
      
      PR_INGRESAR_NOTA(L_ID, P_DEPARTAMENTO, P_CURSO, P_NOTA);
      
      EXCEPTION
      
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Codigo de error: ' || SQLCODE || ': ' || SQLERRM);
      
    END PR_INGRESAR_NOTA;  
     
   PROCEDURE PR_MOSTRAR_ALUMNOS (P_ID_CLASE CLASSES.COURSE%TYPE,  
                                    P_FLAG BOOLEAN) IS 
     
    
    INDICE BINARY_INTEGER;
    ID STUDENTS.ID%TYPE;
    
    BEGIN 
     
    --PRIMERO DEBE VERIFICAR QUE EL CURSO EXISTE. USA LA TABLA EN MEMORIA
    --PARA EVITAR ACCEDER DE ENTRADA A LA BD.
      IF (FU_CLASE_EXISTE(P_ID_CLASE)) THEN
        
       
        FOR r_est IN (SELECT * FROM REGISTERED_STUDENTS RS WHERE RS.COURSE = P_ID_CLASE) 
         LOOP
          
          ID := r_est.STUDENT_ID;
          
          CASE P_FLAG 
            
            WHEN TRUE THEN  --SOLO MUESTRA LOS APROBADOS
              
              IF (r_est.GRADE = 'A' OR r_est.GRADE = 'B' OR r_est.GRADE = 'C') THEN
                
                DBMS_OUTPUT.PUT_LINE('ID ESTUDIANTE: ' || ID || ' APPELLIDO: ' || T_ESTUDIANTES(ID).LAST_NAME || 
                                     ' NOMBRE: ' || T_ESTUDIANTES(ID).FIRST_NAME || ' CARRERA: ' || T_ESTUDIANTES(ID).MAJOR
                                     || ' CREDITOS ACTUALES: ' || T_ESTUDIANTES(ID).CURRENT_CREDITS);
              END IF;
              
            WHEN FALSE THEN  --SOLO MUESTRA LOS DESAPROBADOS
              
              IF (r_est.GRADE = 'D' OR r_est.GRADE = 'E') THEN
            
                DBMS_OUTPUT.PUT_LINE(' ID ESTUDIANTE: ' || ID || ' APPELLIDO: ' || T_ESTUDIANTES(ID).LAST_NAME || 
                                     ' NOMBRE: ' || T_ESTUDIANTES(ID).FIRST_NAME || ' CARRERA: ' || T_ESTUDIANTES(ID).MAJOR
                                     || ' CREDITOS ACTUALES: ' || T_ESTUDIANTES(ID).CURRENT_CREDITS);
            
              END IF;
              
            ELSE --EN CASO DE QUE P_FLAG SEA NULO, MUESTRA LOS APROBADOS Y DESAPROBADOS
                
                DBMS_OUTPUT.PUT_LINE(' ID ESTUDIANTE: ' || ID || ' APPELLIDO: ' || T_ESTUDIANTES(ID).LAST_NAME || 
                                     ' NOMBRE: ' || T_ESTUDIANTES(ID).FIRST_NAME || ' CARRERA: ' || T_ESTUDIANTES(ID).MAJOR
                                     || ' CREDITOS ACTUALES: ' || T_ESTUDIANTES(ID).CURRENT_CREDITS);
            
         END CASE;
            
        
        END LOOP;
        
      ELSE
        
        RAISE_APPLICATION_ERROR(-20002, 'EL CURSO NO EXISTE');
      
      END IF;
	
    EXCEPTION
      WHEN E_CURSO_ID THEN
        DBMS_OUTPUT.PUT_LINE('EL CURSO NO EXISTE');
        
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Codigo de error: ' || SQLCODE || ': ' || SQLERRM);
     
    END PR_MOSTRAR_ALUMNOS;  
     
    PROCEDURE PR_MOSTRAR_ALUMNOS IS 
     
     R_CLASE BINARY_INTEGER;
 
     
    BEGIN 
       
      R_CLASE := T_CLASES_SEC.FIRST;

      FOR i IN 1..T_CLASES_SEC.COUNT LOOP
        
        DBMS_OUTPUT.PUT_LINE(' ');
        DBMS_OUTPUT.PUT_LINE('ID CURSO: ' || T_CLASES_SEC(R_CLASE).COURSE || ' DESCRIPCION: ' || 
                             T_CLASES_SEC(R_CLASE).DESCRIPTION);
        DBMS_OUTPUT.PUT_LINE(' ');
        
        --LLAMA A MOSTRAR ALUMNOS CON P_FLAG NULO ASI MUESTRA TODOS LOS CURSOS
        PR_MOSTRAR_ALUMNOS(T_CLASES_SEC(R_CLASE).COURSE, NULL);  
      
        R_CLASE := T_CLASES_SEC.NEXT(R_CLASE);
      END LOOP;
      
      EXCEPTION
      
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Codigo de error: ' || SQLCODE || ': ' || SQLERRM);
     
    END PR_MOSTRAR_ALUMNOS; 
-----------------------------------------------------------------------------------------------------------------------  
   /* ZONA DE ONE TIME ONLY */ 
   BEGIN 
    
    FOR R_ESTUDIANTE IN C_ESTUDIANTE LOOP -- LA CARGAMOS ASI POR Q SOMOS GROXOS :D 
      T_ESTUDIANTES(R_ESTUDIANTE.ID).FIRST_NAME:= R_ESTUDIANTE.FIRST_NAME; 
      T_ESTUDIANTES(R_ESTUDIANTE.ID).LAST_NAME := R_ESTUDIANTE.LAST_NAME; 
      T_ESTUDIANTES(R_ESTUDIANTE.ID).MAJOR:= R_ESTUDIANTE.MAJOR; 
      T_ESTUDIANTES(R_ESTUDIANTE.ID).CURRENT_CREDITS:= R_ESTUDIANTE.CURRENT_CREDITS; 
    END LOOP; 
    
    SELECT * 
    BULK COLLECT INTO T_CLASES_SEC 
    FROM CLASSES; 
        

END PA_ESTUDIANTES;