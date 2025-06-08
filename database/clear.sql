DROP TYPE IF EXISTS equipment_type CASCADE;
DROP TYPE IF EXISTS equipment_status CASCADE;

DROP VIEW IF EXISTS employees_view;

DROP TRIGGER IF EXISTS pesel_check ON employees CASCADE;
DROP FUNCTION IF EXISTS pesel_check CASCADE;

DROP TABLE IF EXISTS
    schedule_exception_types,
    employee_schedule,
    employee_departments_history,
    employee_positions_history,
    employee_teams_history,
    departments,
    addresses,
    cities,
    regions,
    countries,
    schedule_exceptions,
    position_schedules,
    employee_days,
    vacations,
    tasks,
    teams,
    projects,
    employees,
    positions,
    employee_name_history,
    head_departments_history,
    equipment,
    equipment_status_history,
    employee_equipment_history
CASCADE;



drop table if exists employee_name_history cascade;

drop table if exists head_departments_history cascade;

drop table if exists employee_departments_history cascade;

drop table if exists departments cascade;

drop table if exists employee_teams_history cascade;

drop table if exists employee_schedule cascade;

drop table if exists employer_salary cascade;

drop table if exists schedule_exceptions cascade;

drop table if exists schedule_exception_types cascade;

drop table if exists vacations cascade;

drop table if exists employee_positions_history cascade;

drop table if exists positions cascade;

drop table if exists tasks cascade;

drop table if exists teams cascade;

drop table if exists projects cascade;

drop table if exists equipment_status_history cascade;

drop type if exists equipment_status cascade;

drop table if exists employee_equipment_history cascade;

drop table if exists employees cascade;

drop table if exists addresses cascade;

drop table if exists cities cascade;

drop table if exists regions cascade;

drop table if exists countries cascade;

drop table if exists equipment cascade;

drop type if exists equipment_type cascade;

drop view if exists employees_view cascade;

drop view if exists departments_view cascade;

drop view if exists teams_view cascade;

drop function if exists pesel_check() cascade;

drop function if exists employee_name_change() cascade;

drop function if exists check_and_close_position() cascade;

drop function if exists check_single_active_position() cascade;

drop function if exists check_employee_inserted_correctly() cascade;

drop function if exists add_employee(varchar, varchar, varchar, char, varchar, varchar, varchar, char, integer, integer,
                                     date, varchar, date, varchar, date, varchar, date, date) cascade;

drop function if exists check_departments_consistency() cascade;

drop function if exists create_full_address(varchar, varchar, varchar, varchar, varchar, varchar) cascade;

drop function if exists check_unique_active_head() cascade;

drop function if exists check_unique_active_position() cascade;

drop function if exists check_unique_active_department() cascade;

drop function if exists check_unique_active_team() cascade;

drop function if exists check_unique_active_vacation() cascade;

drop function if exists add_employee(varchar, varchar, varchar, char, varchar, varchar, varchar, char, integer, integer,
                                     date, varchar, integer, date, date, varchar, date, date) cascade;


