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


CREATE EVENT TRIGGER log_ddl_info ON ddl_command_end EXECUTE PROCEDURE log_ddl();

CREATE EVENT TRIGGER log_ddl_drop_info ON sql_drop EXECUTE PROCEDURE log_ddl_drop();


