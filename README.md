# mockserver
Mock API server


How to
Create a repository on GitHub (harimarlabs/mockserver)
  
Create a db.json file
  
Visit https://my-json-server.typicode.com/harimarlabs/mockserver to access your server




Event triggers: These triggers are different from regular triggers, which are attached to a single table and capture only Data Manipulation Language(DML) events. Event triggers are global to a particular database and are capable of capturing DDL events

An event trigger fires whenever the event with which it is associated occurs in the database in which it is defined. Currently, the only supported events are ddl_command_start, ddl_command_end, table_rewrite and sql_drop. Support for additional events may be added in future releases

The ddl_command_start event occurs just before the execution of a CREATE, ALTER, DROP, SECURITY LABEL, COMMENT, GRANT or REVOKE command. ddl_command_start also occurs just before the execution of a SELECT INTO command, since this is equivalent to CREATE TABLE AS.

The ddl_command_end event occurs just after the execution of this same set of commands. To obtain more details on the DDL operations that took place, use the set-returning function pg_event_trigger_ddl_commands() from the ddl_command_end event trigger code. Note that the trigger fires after the actions have taken place (but before the transaction commits), and thus the system catalogs can be read as already changed.

The sql_drop event occurs just before the ddl_command_end event trigger for any operation that drops database objects. To list the objects that have been dropped, use the set-returning function pg_event_trigger_dropped_objects() from the sql_drop event trigger code. Note that the trigger is executed after the objects have been deleted from the system catalogs, so it's not possible to look them up anymore.
The table_rewrite event occurs just before a table is rewritten by some actions of the commands ALTER TABLE and ALTER TYPE
Event triggers are created using the command CREATE EVENT TRIGGER. In order to create an event trigger, you must first create a function with the special return type event_trigger. This function need not (and may not) return a value; the return type serves merely as a signal that the function is to be invoked as an event trigger.
If more than one event trigger is defined for a particular event, they will fire in alphabetical order by trigger name.

CREATE EVENT TRIGGER name
    ON event
    [ WHEN filter_variable IN (filter_value [, ... ]) [ AND ... ] ]
    EXECUTE { FUNCTION | PROCEDURE } function_name()

https://www.postgresql.org/docs/current/sql-createeventtrigger.html


Event triggers can be a very powerful tool for auditing and security. While the example shown demonstrates how event triggers can be used as an auditing or bookkeeping tool, other possible uses of this feature include:
1.	Monitoring DDL performance
2.	Restricting certain DDL commands for some users
3.	Performing replication of DDL to subscriber nodes in a Logical Replication setup


CREATE TABLE ddl_history (

  id serial primary key,

  ddl_date timestamptz,

  ddl_tag text,

  object_name text

);


CREATE OR REPLACE FUNCTION log_ddl()

  RETURNS event_trigger AS $$

DECLARE

  audit_query TEXT;

  r RECORD;

BEGIN

  IF tg_tag <> 'DROP TABLE'

  THEN

    r := pg_event_trigger_ddl_commands();

    INSERT INTO ddl_history (ddl_date, ddl_tag, object_name) VALUES (statement_timestamp(), tg_tag, r.object_identity);

  END IF;

END;

$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION log_ddl_drop()

  RETURNS event_trigger AS $$

DECLARE

  audit_query TEXT;

  r RECORD;

BEGIN

  IF tg_tag = 'DROP TABLE'

  THEN

    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() 

    LOOP

      INSERT INTO ddl_history (ddl_date, ddl_tag, object_name) VALUES (statement_timestamp(), tg_tag, r.object_identity);

    END LOOP;

  END IF;

END;

$$ LANGUAGE plpgsql;

New Export mechanism to update LZ using real time json data 

Get single record from the Queue, below is the record sample: 

{ 

'username': 2, 

'course_id': 'course-v1:VERITAS+TQ111+2023', 

'mode': 'start/progress/complete', 

'total_number_of_lessons': 100, 

'lesson_number': 4, 

'lesson_name': 'Lesson 4', 

'lesson_grade': 100, 

'overall_grade_percentage': 98, 

'overall_progress_percentage': 100, 

'lesson_started_timestamp': '2015-10-28T10:15', 

'lesson_completed_timestamp': '2015-10-28T10:45' 

} 

 

Run the below query in Landing zone DB to select the respective record 

select csm.* from course_student_mapping csm  

left join xened_netsuite_course_mapping xncm on xncm.id = csm.course_id  

left join users u on u.id = csm.user_id  

where xncm.xened_course_id = '<course_id>' and u.sso_id = '<username>' 

Update the record with below combinations. Left side is the column name and the right side is the record data from queue 

grade => overall_grade_percentage, 

total_lessons => total_number_of_lessons, 

completed_till => lesson_number, 

progress => overall_progress_percentage, 

Also update the below records on conditional basis: 

If the 'mode' value is equal to 'start', then add below column in the update array: 

status => 'In progress', 

started_at => lesson_started_timestamp(YYYY-MM-DD HH:MM:SS), 

expiry_date => +1 year from the lesson_started_timestamp column 

Else if the 'mode' value is equal to 'complete', then add below column in the update array: 

status => 'Completed' 

 

Run the below query to check whether the grade data exists or not. 

select * from course_grade_detail cgd 

where cgd.course_mapping_id = 191 and cgd.lesson = '<lesson_name_from_JSON>' 

If the record exists, check the 'grade' value from the above query and the 'lesson_grade' value from json is different. If so, update the 'grade' value in the table with the latest 'lesson_grade' value. 

 

 

 

 

If the record does not exist, insert a new record with the below columns. 

course_mapping_id => <course_student_mapping.id>, 

user_id => <course_student_mapping.user_id>, 

course_id => <course_student_mapping.course_id>, 

lesson => <lesson_name_from_JSON>, 

grade => <lesson_grade>, 

completed_at => <lesson_completed_timestamp>(YYYY-MM-DD HH:MM:SS) 

  

 


CREATE EVENT TRIGGER log_ddl_info ON ddl_command_end EXECUTE PROCEDURE log_ddl();

CREATE EVENT TRIGGER log_ddl_drop_info ON sql_drop EXECUTE PROCEDURE log_ddl_drop();


