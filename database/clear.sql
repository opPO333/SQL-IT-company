drop table if exists employee_name_history cascade;

drop table if exists head_departments_history cascade;

drop table if exists employee_departments_history cascade;

drop table if exists departments cascade;

drop table if exists employee_teams_history cascade;

drop table if exists employee_schedule cascade;

drop table if exists employee_salary cascade;

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

drop view if exists teams_view cascade;

drop view if exists employees_view cascade;

drop view if exists departments_view cascade;

drop view if exists employee_departments_history_view cascade;

drop function if exists pesel_check() cascade;

drop function if exists employee_name_change() cascade;

drop function if exists check_and_close_position() cascade;

drop function if exists check_employee_inserted_correctly() cascade;

drop function if exists add_employee(varchar, varchar, varchar, char, varchar, varchar, varchar, char, integer, date,
                                     varchar, integer, integer, integer, date, date, varchar, date, date) cascade;

drop function if exists check_departments_consistency() cascade;

drop function if exists create_full_address(varchar, varchar, varchar, varchar, varchar, varchar) cascade;

drop function if exists check_unique_active_head() cascade;

drop function if exists check_unique_active_position() cascade;

drop function if exists check_unique_active_department() cascade;

drop function if exists check_unique_active_team() cascade;

drop function if exists check_unique_active_vacation() cascade;

drop function if exists employees_view_insert_tr() cascade;

drop function if exists trg_employees_view_update() cascade;

drop function if exists manage_employees_view_delete() cascade;

